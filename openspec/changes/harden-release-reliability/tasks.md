## Implementation

### `manage_package.sh`

- [x] Add `set -euo pipefail` to `manage_package.sh`.
- [x] Use `curl --fail --show-error --silent --location` in `manage_package.sh`.
- [x] Update `manage_package.sh` to fail early on unset variables, failed curls, missing dependencies, invalid JSON, and empty search results.

### GitHub Actions Release Workflow

- [x] Add `set -euo pipefail` to Bash-based GitHub Actions workflow scripts where supported.
- [x] Use `curl --fail --show-error --silent --location` for release metadata and artifact downloads in GitHub Actions.
- [x] Pin Mage to a known-good version instead of `@latest`.
- [x] Pin nfpm to a known-good version instead of `@latest`.
- [x] Validate upstream release metadata before continuing:
  - [x] `tag_name` is present and not `null`.
  - [x] `tarball_url` is present and not `null`.
  - [x] changelog handling is safe when the release body is empty.
- [x] After `mage build`, verify:
  - [x] `source/package-registry` exists.
  - [x] `source/package-registry` is executable.
  - [x] `source/package-registry --version` exits successfully.

### Package Artifact Smoke Tests

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

### Tar Archive Layout

- [ ] Change tar.gz staging from `usr/bin` to `usr/local/bin`, or otherwise make the archive service file and binary path consistent.

### Static Checks

- [ ] Add CI checks for:
  - [ ] `shellcheck`.
  - [ ] `yamllint`.
  - [ ] `actionlint`.

## Verification

- [ ] Manual `workflow_dispatch` builds and publishes only after all validations pass.
- [ ] Generated `.deb`, `.rpm`, and `.tar.gz` artifacts expose a consistent binary path.
- [ ] A deliberately invalid upstream metadata response fails before download/build steps.
- [ ] A deliberately broken package artifact fails in smoke tests before release creation.
