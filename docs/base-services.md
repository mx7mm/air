# Base Services (v0.3)

This document defines the minimal service layer for Air runtime.

## Startup Order

Air init (`/etc/init.d/rcS`) executes a deterministic step order from:

`/etc/air/service-order.conf`

Current sequence:

1. `mount-core` (proc/sys/dev/devpts)
2. `mount-runtime` (`/run`, `/tmp` as tmpfs)
3. `setup-logging` (volatile logs under `/run/log/air`)
4. `mount-data` (optional persistent logs and state under `/data`)
5. `system-identity` (hostname and printk level)
6. `immutability-check` (optional smoke check)
7. `remount-root-ro` (runtime root remount read-only)
8. `boot-healthcheck` (optional summary check)
9. `launch-session` (`air-session` -> `air-kiosk`)

This keeps boot behavior deterministic while still allowing debug/runtime flags.

## Logging Policy

No runtime logs are written into immutable root.

- Volatile logs: `/run/log/air`
- Boot log: `/run/log/air/boot.log`
- Runtime log: `/run/log/air/runtime.log`
- Persistent log mirror (when `/data` is mounted): `/data/log/air`

Runtime components (`rcS`, `air-session`, `air-kiosk`, `air-healthcheck`) write only to `/run` and optional `/data`.

## Healthcheck

Command:

`air-healthcheck [--mode=boot|--mode=runtime]`

Checks include:

- mount assumptions (`/`, `/run`, `/tmp`, `/data`)
- core runtime assumptions (flags loader, version file, log dir)
- key process expectations for selected mode

Outputs:

- `PASS: ...` / `FAIL: ...` per check
- final `RESULT: PASS` or `RESULT: FAIL` summary

Integration points:

- Boot flow via `AIR_HEALTHCHECK_ON_BOOT=1` (default)
- Debug/stabilization flow via manual runtime command
