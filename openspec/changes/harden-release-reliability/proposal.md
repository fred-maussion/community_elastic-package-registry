# Harden Release Reliability

## Why

The release workflow builds community packages from the upstream Elastic Package Registry and publishes them automatically. Small failures in API handling, toolchain drift, package layout, or artifact validation can produce broken releases or make failures hard to diagnose.

This change improves release reproducibility and adds verification before artifacts are published.

## What Changes

- Add strict shell behavior and safer curl defaults in release automation and helper scripts.
- Pin Mage and nfpm versions used by GitHub Actions.
- Validate upstream GitHub release metadata before downloading and building.
- Verify that the built `package-registry` binary exists, is executable, and reports a version.
- Add package smoke tests for generated Debian and RPM artifacts.
- Align the tar.gz archive layout with the packaged service path.
- Add repository checks for shell, YAML, and GitHub Actions workflow quality.

## Impact

- Touches `.github/workflows/release-monitor.yml`.
- Touches `manage_package.sh`.
- Touches tar.gz staging layout in the release workflow.
- May add CI jobs or commands for `shellcheck`, `yamllint`, and `actionlint`.
- Does not change the package-registry application source code.
