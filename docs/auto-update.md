# Auto Update Flow (v0.4 foundation)

Air uses manual update trigger from inside the OS interface.

## Device Flow

At boot, no automatic install happens by default (`AIR_AUTO_UPDATE=0`).
Updates are triggered manually by user command:

- `update` (inside Air interface)

Manual `update` command calls `air-auto-update run`, which does:

1. Read current version from runtime version path (`AIR_VERSION_FILE`)
2. Load channel manifest from `AIR_UPDATE_MANIFEST_URL`
3. Compare current vs target version
4. Download package when target is newer
5. Validate and apply via `air-update check` + `air-update apply`
6. Write state file: `/data/updates/state/auto-update.json`
7. Optional reboot when `AIR_AUTO_UPDATE_REBOOT=1`

`air-update apply` now:

- stages payload under `/data/updates/staged/<package_version>/`
- activates current payload under `/data/updates/current/`

Runtime automatically prefers `/data/updates/current/VERSION` when present.

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

If `latest.json` becomes visible to devices (mounted/synced/served), users can trigger apply+activate from interface using `update`.

## GitHub as Central Update Source

GitHub Releases can be used as the central distribution point.

One-command release (current local version):

```bash
scripts/release-current-to-github.sh --repo mx7mm/air
```

If you want the next patch version automatically:

```bash
scripts/release-current-to-github.sh --repo mx7mm/air --next-patch
```

Publish package + channel manifest:

```bash
scripts/publish-update-github.sh --repo mx7mm/air --package ./air-update-v0.4.1.tar
```

This uploads:

- versioned package asset to release tag `v0.4.1` (or provided `--version-tag`)
- mutable channel manifest asset (`latest.json`) to release tag `air-channel`

Resulting channel URL pattern:

`https://github.com/<owner>/<repo>/releases/download/air-channel/latest.json`

Set this URL on devices:

`AIR_UPDATE_MANIFEST_URL=https://github.com/<owner>/<repo>/releases/download/air-channel/latest.json`

Note for private repos: device access requires authenticated download support (token/cookie/proxy).

## Scope Note

Current stage is automated download + validate + activation of update payload data.
Full partition/slot switch and rollback orchestration remains part of later v0.4 work.
