# Air

A minimal, cloud-based operating system with a custom environment and apps.

Air is built on the Linux kernel but hides all traditional Linux interfaces. Users see only Air—a clean, purpose-built experience.

## Quick Start

```bash
./scripts/build.sh
```

Note:
- The build script runs on Linux hosts. On macOS, build via Linux VM/SSH host.

### ARM64 Runtime (Direct QEMU)

Run the built ARM64 disk without UTM:

```bash
./scripts/run-qemu-arm64.sh
```

Notes:
- The script boots with serial console (`-nographic`) for reliable debugging.
- The script auto-creates a compatible 64MB UEFI vars file when needed.

### Interface + Version

The default primary interface currently prints:

`Willkommen`

Version metadata remains in:

`/etc/air/VERSION`

Current value:

`v0.1.1`

Source file in this repo:

`board/air/rootfs-overlay/etc/air/VERSION`

## Documentation

- [Vision](docs/vision.md) – What Air will become
- [Architecture](docs/architecture.md) – How the system is structured
- [Base Services](docs/base-services.md) – Startup order, logging, healthcheck
- [Update Format](docs/update-package-format.md) – Local package format (`air-update-1`)
- [Auto Update](docs/auto-update.md) – Central publish + automatic device staging
- [Release Policy](docs/release-policy.md) – When and how releases are created
- [File Versioning](docs/file-versioning.md) – Per-file version tags and bump rules
- [Journal 2026-02-11](docs/journal/2026-02-11.md) – Detailed feature log for today
- [Glossary](docs/glossary.md) – Technical terms explained

GitHub Releases can be used as the central update source (`latest.json` channel + versioned package assets).
Quick publish command:
`scripts/release-current-to-github.sh --repo mx7mm/air`

## Project Status

**Phase 1: Foundation** – Building a minimal bootable system.

See [CHANGELOG.md](CHANGELOG.md) for progress.

## License

MIT

## Repo Layout (Simplified)

- `air.img` (root): visible image entry file.
- `README.md` (root): quick info.
- `sammelordner/`: all other project files.
