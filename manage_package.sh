#!/bin/bash

set -euo pipefail

usage() {
  echo "Usage: $0 <kibana_version> <package_name> [--debug] [--insecure]"
  echo "Environment variables KIBANA_URL and KIBANA_API_KEY must be set."
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1"
    exit 7
  fi
}

url_encode() {
  jq -nr --arg value "$1" '$value|@uri'
}

# Function to upload package to Kibana using installPackageByUpload API
upload_to_kibana() {
  local package_file="$1"

  # Read Kibana URL and API Key from environment variables
  local kibana_url="${KIBANA_URL:-}"
  local kibana_api_key="${KIBANA_API_KEY:-}"
  local upload_endpoint="${kibana_url%/}${UPLOAD_PATH}"

  if [ -z "$kibana_url" ] || [ -z "$kibana_api_key" ]; then
    echo "Kibana URL and API key are required for uploading the package."
    echo "Ensure the environment variables KIBANA_URL and KIBANA_API_KEY are set."
    exit 5
  fi

  echo "Uploading package '$package_file' to Kibana at $upload_endpoint..."

  # Perform the upload and capture the response
  response=$(curl "${CURL_STATUS_ARGS[@]}" -w "\nHTTP_CODE:%{http_code}" -X POST "$upload_endpoint" \
    -H "Content-Type: application/zip" \
    -H "Authorization: ApiKey $kibana_api_key" \
    -H "kbn-xsrf: true" \
    --data-binary @"$package_file")

  # Extract the HTTP status code
  http_code=$(echo "$response" | grep "HTTP_CODE:" | sed 's/HTTP_CODE://')

  # Extract the response body
  response_body=$(echo "$response" | sed '/HTTP_CODE:/d')

  if [ "$http_code" -eq 200 ]; then
    echo "Package uploaded successfully to Kibana."
  else
    echo "Failed to upload package to Kibana. HTTP status code: $http_code"
    echo "Response body: $response_body"
    exit 6
  fi
}

# Check if Kibana version and package name are provided
if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
  usage
  exit 1
fi

KIBANA_VERSION=$1
PACKAGE_NAME=$2
BASE_URL="https://epr.elastic.co"
UPLOAD_PATH="/api/fleet/epm/packages"
DEBUG=false
INSECURE_FLAG=()

# Check for additional flags
for arg in "${@:3}"; do
  case $arg in
    --debug)
      DEBUG=true
      ;;
    --insecure)
      INSECURE_FLAG=(--insecure)
      ;;
    *)
      echo "Unknown option: $arg"
      usage
      exit 1
      ;;
  esac
done

require_command curl
require_command jq

# Ensure Kibana URL and API key are set in the environment
if [ -z "${KIBANA_URL:-}" ] || [ -z "${KIBANA_API_KEY:-}" ]; then
  echo "KIBANA_URL or KIBANA_API_KEY environment variable is not set. Exiting."
  exit 5
fi

ENCODED_PACKAGE_NAME=$(url_encode "$PACKAGE_NAME")
ENCODED_KIBANA_VERSION=$(url_encode "$KIBANA_VERSION")
SEARCH_URL="$BASE_URL/search?package=$ENCODED_PACKAGE_NAME&kibana.version=$ENCODED_KIBANA_VERSION"

CURL_ARGS=(--fail --show-error --silent --location)
CURL_STATUS_ARGS=(--show-error --silent --location)
CURL_ARGS+=("${INSECURE_FLAG[@]}")
CURL_STATUS_ARGS+=("${INSECURE_FLAG[@]}")

# Fetch data from the Elastic Package Registry
echo "Searching for package '$PACKAGE_NAME' for Kibana version '$KIBANA_VERSION' on Elastic Package Registry..."
RESPONSE=$(curl "${CURL_ARGS[@]}" "$SEARCH_URL")

# Output debug information if debug flag is set
if $DEBUG; then
  echo "DEBUG: Response from Elastic Package Registry:"
  echo "$RESPONSE"
fi

# Check if response is empty
if [ -z "$RESPONSE" ]; then
  echo "No response from Elastic Package Registry. Exiting."
  exit 2
fi

if ! echo "$RESPONSE" | jq -e 'type == "array"' >/dev/null; then
  echo "Invalid response from Elastic Package Registry: expected a JSON array."
  exit 2
fi

if [ "$(echo "$RESPONSE" | jq 'length')" -eq 0 ]; then
  echo "No package found for '$PACKAGE_NAME' and Kibana version '$KIBANA_VERSION'."
  exit 3
fi

# Extract the download path from the JSON response
DOWNLOAD_PATH=$(echo "$RESPONSE" | jq -r '.[0].download')

# Check if download path was found
if [ -z "$DOWNLOAD_PATH" ] || [ "$DOWNLOAD_PATH" = "null" ]; then
  echo "No download path found for package '$PACKAGE_NAME'. Exiting."
  exit 3
fi

# Construct the full download URL
if [[ "$DOWNLOAD_PATH" == http://* || "$DOWNLOAD_PATH" == https://* ]]; then
  DOWNLOAD_URL="$DOWNLOAD_PATH"
else
  DOWNLOAD_URL="$BASE_URL$DOWNLOAD_PATH"
fi

# Download the package
PACKAGE_FILE=$(basename "$DOWNLOAD_PATH")
echo "Downloading package from $DOWNLOAD_URL..."
curl "${CURL_ARGS[@]}" -o "$PACKAGE_FILE" "$DOWNLOAD_URL"

# Check if download succeeded
if [ ! -s "$PACKAGE_FILE" ]; then
  echo "Failed to download package. Exiting."
  exit 4
fi

echo "Package downloaded successfully: $PACKAGE_FILE"

# Upload to Kibana using environment variables
upload_to_kibana "$PACKAGE_FILE"
