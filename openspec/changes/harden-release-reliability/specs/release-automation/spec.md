## ADDED Requirements

### Requirement: Strict Release Shell Execution

Release automation SHALL fail fast on command errors, unset variables, and failed pipelines wherever the active shell supports those controls.

#### Scenario: Upstream download fails

- **WHEN** the release workflow downloads upstream source or package artifacts
- **AND** the remote endpoint returns a non-success HTTP response
- **THEN** the workflow SHALL fail the current job before building or publishing artifacts
- **AND** the logs SHALL include the curl error output

#### Scenario: Pipeline command fails

- **WHEN** a command in a release workflow pipeline fails
- **THEN** the workflow SHALL treat the pipeline as failed

### Requirement: Pinned Release Toolchain

Release automation SHALL use explicit versions for third-party build tools installed during CI.

#### Scenario: Mage is installed

- **WHEN** the workflow installs Mage
- **THEN** it SHALL install a pinned version instead of `latest`

#### Scenario: nfpm is installed

- **WHEN** the workflow installs nfpm
- **THEN** it SHALL install a pinned version instead of `latest`

### Requirement: Upstream Release Metadata Validation

Release automation SHALL validate required upstream release metadata before downloading source archives.

#### Scenario: Latest upstream release has no tag

- **WHEN** the GitHub API response has an empty or `null` `tag_name`
- **THEN** the workflow SHALL fail before the version comparison step proceeds

#### Scenario: Latest upstream release has no tarball URL

- **WHEN** the GitHub API response has an empty or `null` `tarball_url`
- **THEN** the workflow SHALL fail before attempting to download source code

#### Scenario: Latest upstream release has no body

- **WHEN** the GitHub API response has an empty or `null` release body
- **THEN** the workflow SHALL continue with safe default release notes

### Requirement: Built Binary Verification

Release automation SHALL verify the built `package-registry` binary before packaging.

#### Scenario: Binary is missing

- **WHEN** the build step completes without producing `source/package-registry`
- **THEN** the workflow SHALL fail before building `.deb`, `.rpm`, or `.tar.gz` artifacts

#### Scenario: Binary is not executable

- **WHEN** `source/package-registry` exists but is not executable
- **THEN** the workflow SHALL fail before building package artifacts

#### Scenario: Binary cannot report version

- **WHEN** `source/package-registry --version` exits with a non-zero status
- **THEN** the workflow SHALL fail before building package artifacts

### Requirement: Package Smoke Tests

Release automation SHALL smoke test generated Debian and RPM packages before creating a GitHub release.

#### Scenario: Debian package is generated

- **WHEN** the workflow creates a `.deb` artifact
- **THEN** the workflow SHALL install it in disposable Ubuntu LTS and Debian LTS environments
- **AND** the Ubuntu LTS environments SHALL include the latest Ubuntu LTS release and the previous Ubuntu LTS release
- **AND** the Debian LTS environments SHALL include the latest Debian LTS release and the previous Debian LTS release
- **AND** verify the expected binary, config file, environment file, and systemd service paths exist
- **AND** verify the installed binary can report its version

#### Scenario: RPM package is generated

- **WHEN** the workflow creates a `.rpm` artifact
- **THEN** the workflow SHALL install it in disposable RHEL-compatible environments
- **AND** the RHEL-compatible environments SHALL cover RHEL 8 and RHEL 9
- **AND** verify the expected binary, config file, environment file, and systemd service paths exist
- **AND** verify the installed binary can report its version

#### Scenario: Smoke test fails

- **WHEN** any package smoke test fails
- **THEN** the workflow SHALL fail before generating checksums or creating a GitHub release

### Requirement: Consistent Tar Archive Layout

The tar.gz archive SHALL use a binary path consistent with the included service file.

#### Scenario: Tar archive is created

- **WHEN** the workflow stages files for the tar.gz archive
- **THEN** the `package-registry` binary path in the archive SHALL match the path used by `package-registry.service`

### Requirement: Repository Static Checks

The repository SHALL provide automated checks for shell scripts, YAML files, and GitHub Actions workflows.

#### Scenario: Shell scripts are changed

- **WHEN** shell scripts or shell snippets in workflow files are changed
- **THEN** CI SHALL run shell linting before release automation is considered healthy

#### Scenario: YAML files are changed

- **WHEN** YAML files are changed
- **THEN** CI SHALL run YAML linting before release automation is considered healthy

#### Scenario: GitHub Actions workflows are changed

- **WHEN** files under `.github/workflows` are changed
- **THEN** CI SHALL run GitHub Actions workflow linting before release automation is considered healthy
