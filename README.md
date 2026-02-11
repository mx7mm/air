# Air

A minimal, cloud-based operating system with a custom environment and apps.

Air is built on the Linux kernel but hides all traditional Linux interfaces. Users see only Air—a clean, purpose-built experience.

## Quick Start

```bash
./scripts/build.sh
```

## Build Variants

Air now has two build variants:

- x86_64 (default): `./scripts/build.sh`
- ARM64 (AArch64): `AIR_DEFCONFIG=air_arm64_defconfig ./scripts/build.sh`

Both variants produce a `disk.img` under the chosen build directory
(default: `~/air-build`).

## Documentation

- [Vision](docs/vision.md) – What Air will become
- [Architecture](docs/architecture.md) – How the system is structured
- [Glossary](docs/glossary.md) – Technical terms explained

## Project Status

**Phase 1: Foundation** – Building a minimal bootable system.

See [CHANGELOG.md](CHANGELOG.md) for progress.

## License

MIT
