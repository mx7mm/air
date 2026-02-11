# Auto Update Flow (v0.4 foundation)

Air can stage newer versions automatically at boot after a central build/publish step.

## Device Flow

At boot, `rcS` runs `air-auto-update run` (when enabled).

`air-auto-update` does:

1. Read current version from `/etc/air/VERSION`
2. Load channel manifest from `AIR_UPDATE_MANIFEST_URL`
3. Compare current vs target version
4. Download package when target is newer
5. Validate and stage via `air-update check` + `air-update apply`
6. Write state file: `/data/updates/state/auto-update.json`
7. Optional reboot when `AIR_AUTO_UPDATE_REBOOT=1`

## Runtime Flags

Configured in `/etc/air/runtime.conf`:

- `AIR_AUTO_UPDATE` (`0|1`)
- `AIR_AUTO_UPDATE_REBOOT` (`0|1`)
- `AIR_UPDATE_MANIFEST_URL` (local path, `file://`, or `http(s)://`)

Default channel reference:

`/data/updates/channel/latest.json`

## Central Publish Flow

1. Build update package:

```bash
scripts/make-update-package.sh --version v0.4.1 --payload-dir ./payload --output ./air-update-v0.4.1.tar
```

2. Publish channel metadata:

```bash
scripts/publish-update-channel.sh --package ./air-update-v0.4.1.tar --channel-dir ./channel
```

This generates:

- `channel/latest.json`
- `channel/packages/air-update-v0.4.1.tar`

If `latest.json` becomes visible to devices (mounted/synced/served), devices stage the new version automatically on next boot.

## Scope Note

Current stage is automated download + validate + staging. Full slot switch / rollback execution path is handled in later v0.4 issues.
