# Boot Regression Matrix

This document defines the reproducible boot matrix for milestone `v0.2.1`.

## Profiles

| Profile | CPU | RAM | Purpose |
|---|---:|---:|---|
| `baseline` | 4 | 4096 MB | Normal dev runtime baseline |
| `constrained` | 2 | 2048 MB | Lower-resource regression guard |

## Pass Criteria

A boot run is `PASS` only if all are true:

- QEMU reaches `air-ai>` prompt within timeout.
- Log does not contain known fatal markers:
  - `Kernel panic`
  - `Failed to boot both default and fallback entries`
  - `can't find command`

## Script

Run matrix:

```bash
./scripts/boot-regression-matrix.sh
```

Useful overrides:

```bash
ATTEMPTS_PER_PROFILE=1 BOOT_TIMEOUT_SEC=30 ./scripts/boot-regression-matrix.sh
BOOT_MATRIX_PROFILES=baseline ./scripts/boot-regression-matrix.sh
```

Logs are written to:

`/tmp/air-boot-matrix`

## Exit Behavior

- Exit `0`: all matrix runs passed.
- Exit `1`: one or more runs failed.
