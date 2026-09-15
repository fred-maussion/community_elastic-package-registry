#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 <deb|rpm> <container_image> <package_file>"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1"
    exit 2
  fi
}

if [ "$#" -ne 3 ]; then
  usage
  exit 1
fi

PACKAGE_TYPE=$1
CONTAINER_IMAGE=$2
PACKAGE_FILE=$3

case "$PACKAGE_TYPE" in
  deb | rpm)
    ;;
  *)
    echo "Unsupported package type: $PACKAGE_TYPE"
    usage
    exit 1
    ;;
esac

if [ ! -f "$PACKAGE_FILE" ]; then
  echo "Package file not found: $PACKAGE_FILE"
  exit 1
fi

require_command docker

IMAGE_ID=$(echo "$CONTAINER_IMAGE" | tr '/:.' '---')
CONTAINER_NAME="epr-smoke-${PACKAGE_TYPE}-${IMAGE_ID}-$$"
CONTAINER_PACKAGE="/tmp/$(basename "$PACKAGE_FILE")"

cleanup() {
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

trap cleanup EXIT

echo "Starting smoke test for $PACKAGE_FILE on $CONTAINER_IMAGE..."
docker pull "$CONTAINER_IMAGE" >/dev/null
docker run --detach --name "$CONTAINER_NAME" "$CONTAINER_IMAGE" sleep infinity >/dev/null
docker cp "$PACKAGE_FILE" "$CONTAINER_NAME:$CONTAINER_PACKAGE"

docker_exec() {
  docker exec \
    --env PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    "$CONTAINER_NAME" "$@"
}

docker_exec sh -c 'cat > /usr/local/bin/systemctl <<'"'"'EOF'"'"'
#!/bin/sh
echo "systemctl stub: $*" >&2
exit 0
EOF
chmod 0755 /usr/local/bin/systemctl'

case "$PACKAGE_TYPE" in
  deb)
    docker_exec sh -c 'DEBIAN_FRONTEND=noninteractive apt-get update >/dev/null && apt-get install -y ca-certificates curl >/dev/null'
    # shellcheck disable=SC2016
    docker_exec sh -c 'DEBIAN_FRONTEND=noninteractive apt-get install -y "$1" >/dev/null' sh "$CONTAINER_PACKAGE"
    docker_exec dpkg-query -W elastic-package-registry
    ;;
  rpm)
    docker_exec sh -c 'dnf install -y ca-certificates >/dev/null'
    docker_exec dnf install -y "$CONTAINER_PACKAGE"
    docker_exec rpm -q elastic-package-registry
    ;;
esac

docker_exec test -x /usr/local/bin/package-registry
docker_exec /usr/local/bin/package-registry --version
docker_exec test -f /etc/package-registry/config.yml
docker_exec test -f /etc/package-registry/package-registry-env.conf
docker_exec test -f /usr/lib/systemd/system/package-registry.service
docker_exec grep -F /usr/local/bin/package-registry /usr/lib/systemd/system/package-registry.service
docker_exec test -d /var/package-registry/packages

# shellcheck disable=SC2016
docker_exec sh -c '
  set -eu

  EPR_PACKAGE_PATHS_ENABLE_WATCHER=true /usr/local/bin/package-registry \
    -address 127.0.0.1:8080 \
    -config /etc/package-registry/config.yml > /tmp/package-registry.log 2>&1 &
  service_pid=$!

  cleanup_service() {
    kill "$service_pid" >/dev/null 2>&1 || true
    wait "$service_pid" >/dev/null 2>&1 || true
  }

  trap cleanup_service EXIT

  for _ in $(seq 1 30); do
    if curl --fail --silent "http://127.0.0.1:8080/search?package=__smoke_test__&kibana.version=9.0.0" >/dev/null; then
      exit 0
    fi

    if ! kill -0 "$service_pid" >/dev/null 2>&1; then
      cat /tmp/package-registry.log
      exit 1
    fi

    sleep 1
  done

  cat /tmp/package-registry.log
  exit 1
'

echo "Smoke test passed for $PACKAGE_FILE on $CONTAINER_IMAGE."
