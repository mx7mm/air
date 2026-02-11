# Runtime Flags

Air runtime behavior is controlled by a centralized config file:

`/etc/air/runtime.conf`

## Supported Flags

- `AIR_DEBUG` (`0|1`)
- `AIR_REBOOT_ON_EXIT` (`0|1`)
- `AIR_IMMUTABILITY_CHECK` (`0|1`)
- `AIR_IMMUTABILITY_STRICT` (`0|1`)
- `AIR_HEALTHCHECK_ON_BOOT` (`0|1`)
- `AIR_VERSION_FILE` (path)

## Load Order

Flags are resolved in this order:

1. Environment variable (highest priority)
2. Value from `/etc/air/runtime.conf`
3. Built-in default in `air-runtime-flags`

This preserves backward compatibility with existing workflows that use env flags like:

`AIR_DEBUG=1`, `AIR_REBOOT_ON_EXIT=1`

## Runtime Loader

Loader script:

`/usr/bin/air-runtime-flags`

Used by:

- `rcS` init script
- `air-session`
- `air-kiosk`
- `air-immutable-smoke`
