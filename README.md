# Air

A minimal, cloud-based operating system with a custom environment and apps.

Air is built on the Linux kernel but hides all traditional Linux interfaces. Users see only Air—a clean, purpose-built experience.

## Quick Start

```bash
./scripts/build.sh
```

### ARM64 Runtime (Direct QEMU)

Run the built ARM64 disk without UTM:

```bash
./scripts/run-qemu-arm64.sh
```

Notes:
- The script boots with serial console (`-nographic`) for reliable debugging.
- The script auto-creates a compatible 64MB UEFI vars file when needed.

### Dummy AI Version

The kiosk reads its displayed version from:

`/etc/air/VERSION`

Source file in this repo:

`board/air/rootfs-overlay/etc/air/VERSION`

## Documentation

- [Vision](docs/vision.md) – What Air will become
- [Architecture](docs/architecture.md) – How the system is structured
- [Glossary](docs/glossary.md) – Technical terms explained

## Project Status

**Phase 1: Foundation** – Building a minimal bootable system.

See [CHANGELOG.md](CHANGELOG.md) for progress.

## License

MIT
