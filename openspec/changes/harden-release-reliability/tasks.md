## Implementation

- [ ] Add `set -euo pipefail` to Bash-based workflow scripts where supported.
- [ ] Use `curl --fail --show-error --silent --location` for release metadata and artifact downloads.
- [x] Update `manage_package.sh` to fail early on unset variables, failed curls, missing dependencies, invalid JSON, and empty search results.
- [ ] Pin Mage to a known-good version instead of `@latest`.
- [ ] Pin nfpm to a known-good version instead of `@latest`.
- [ ] Validate upstream release metadata before continuing:
  - [ ] `tag_name` is present and not `null`.
  - [ ] `tarball_url` is present and not `null`.
  - [ ] changelog handling is safe when the release body is empty.
- [ ] After `mage build`, verify:
  - [ ] `source/package-registry` exists.
  - [ ] `source/package-registry` is executable.
  - [ ] `source/package-registry --version` exits successfully.
- [ ] Add Debian package smoke tests in disposable Ubuntu LTS environments:
  - [ ] Latest Ubuntu LTS.
  - [ ] Previous Ubuntu LTS.
- [ ] Add Debian package smoke tests in disposable Debian LTS environments:
  - [ ] Latest Debian LTS.
  - [ ] Previous Debian LTS.
- [ ] Add RPM package smoke tests in disposable RHEL-compatible environments:
  - [ ] RHEL 8 compatible environment.
  - [ ] RHEL 9 compatible environment.
- [ ] Smoke tests verify installed file paths, config files, service file, and runnable binary.
- [ ] Change tar.gz staging from `usr/bin` to `usr/local/bin`, or otherwise make the archive service file and binary path consistent.
- [ ] Add CI checks for:
  - [ ] `shellcheck`.
  - [ ] `yamllint`.
  - [ ] `actionlint`.

## Verification

- [ ] Manual `workflow_dispatch` builds and publishes only after all validations pass.
- [ ] Generated `.deb`, `.rpm`, and `.tar.gz` artifacts expose a consistent binary path.
- [ ] A deliberately invalid upstream metadata response fails before download/build steps.
- [ ] A deliberately broken package artifact fails in smoke tests before release creation.
