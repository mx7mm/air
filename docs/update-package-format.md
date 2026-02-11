# Local Update Package Format (`air-update-1`)

This document defines the first local update package format for Air.

## Package Structure

The package is a tar archive containing exactly these files:

- `manifest.json`
- `manifest.sha256`
- `payload.tar`
- `payload.sha256`

## `manifest.json` Fields

Required fields:

- `format_version` (must be `air-update-1`)
- `package_version` (semantic version, e.g. `v0.4.0`)
- `built_at` (UTC timestamp, ISO-8601)
- `payload_file` (currently `payload.tar`)
- `payload_sha256` (sha256 hash of `payload.tar`)

Optional:

- `notes` (free text)

## Validation Rules

`air-update check <package.tar>` validates:

1. Archive is readable and contains required files.
2. `manifest.json` contains all required fields.
3. `format_version` is supported (`air-update-1`).
4. `payload_sha256` in manifest matches actual `payload.tar` hash.
5. `payload.sha256` (if present) matches actual `payload.tar` hash.

If all checks pass, command exits `0`.

## Apply (Staging) Behavior

`air-update apply <package.tar>` currently stages update data under `/data`:

- package copy + extracted payload: `/data/updates/staged/<package_version>/`
- latest staged metadata: `/data/updates/state/last-staged.json`

This is intentionally a staging-only path for v0.4 foundation. Full boot switch + rollback comes in later issues.

## Example Generation

Use:

```bash
scripts/make-update-package.sh --version v0.4.0 --payload-dir ./payload --output ./air-update-v0.4.0.tar
```

Then validate:

```bash
air-update check ./air-update-v0.4.0.tar
```
