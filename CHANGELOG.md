# Changelog

All notable changes to Air are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/).

---

## [Unreleased]

### Added
- Release policy documentation (`docs/release-policy.md`)
- Release notes extractor script (`scripts/extract-release-notes.sh`)
- Daily feature documentation entry (`docs/journal/2026-02-11.md`)
- Per-file versioning manifest (`FILE_VERSIONS.tsv`)
- File versioning helper script (`scripts/file-version.sh`)
- File versioning policy docs (`docs/file-versioning.md`)
- CI enforcement script for file version bumps (`.github/scripts/check-file-versions.sh`)
- Automatic release workflow on version changes (`.github/workflows/release-on-version-change.yml`)
- Tag-based workflow to publish bootable arm64 `.img` assets (`.github/workflows/release-image-on-tag.yml`)
- Dedicated `Air Recovery` GRUB entries for ARM64 and x86_64 emergency shell boot

### Fixed

### Changed
- Release publish scripts now attach version-specific notes from `CHANGELOG.md` by default
- CONTRIBUTING now requires a versioned release for larger user-visible changes
- `air-update apply` now activates payload to `/data/updates/current` after staging
- Runtime version source now automatically prefers `/data/updates/current/VERSION`
- Auto-update flow docs now reflect apply+activate behavior
- Policy workflow now enforces per-file version bump rules
- Release policy now documents automatic publish on version updates
- Auto update install is now manual by default (`AIR_AUTO_UPDATE=0`)
- OS interface now supports `update` and `status` commands for on-demand download/apply
- Repository layout restored to standard root structure (no `sammelordner/` indirection)
- Boot/partition baseline finalized for next image generation:
  - EFI partition size set to 128 MiB
  - rootfs size set to 768 MiB
  - data partition size set to 512 MiB
- Default GRUB boot path now removes serial console output and keeps recovery console separate
- Kernel config fragments now explicitly pin EFI GPT + tmpfs/devtmpfs runtime prerequisites
- Runtime base image version bumped to `v0.2.0` for finalized boot/kernel/partition baseline

---

## [0.1.1] - 2026-02-11

### Added
- MIT License
- Security policy (SECURITY.md)
- Contributing guidelines
- GitHub issue templates (bug, feature request)
- Pull request template
- GitHub Actions CI/CD workflow for automated builds
- Professional documentation for collaborators
- `air-kiosk` dummy AI shell with logo + compact feature view
- Central dummy AI version file at `/etc/air/VERSION`
- Direct ARM64 run script: `scripts/run-qemu-arm64.sh`
- ARM64 kernel image artifact: `Image-arm64`
- Optional init smoke check: `air-immutable-smoke` (`AIR_IMMUTABILITY_CHECK=1`)
- Dedicated GPT `/data` partition in `disk.img` and rootfs mountpoint `/data`
- v0.2 milestone summary page: `docs/milestones/v0.2-immutable-core.md`
- Boot regression matrix script + documentation (`scripts/boot-regression-matrix.sh`, `docs/testing/boot-matrix.md`)
- Runtime mount verification script (`air-verify-mounts`) and stabilization checklist
- Automated `/data` persistence reboot test (`scripts/test-data-persistence.sh`)
- Central runtime flag config + loader (`/etc/air/runtime.conf`, `air-runtime-flags`)
- Deterministic init service order config (`/etc/air/service-order.conf`)
- Boot/runtime healthcheck command (`air-healthcheck`)
- Base services reference doc (`docs/base-services.md`)
- Minimal primary interface entrypoint (`air-primary-interface`)
- Local update command (`air-update`) with `check/apply/status`
- Host update package builder (`scripts/make-update-package.sh`)
- Local update package format documentation (`docs/update-package-format.md`)
- Boot-time auto update command (`air-auto-update`) with version check + auto staging
- Channel publish helper (`scripts/publish-update-channel.sh`)
- GitHub Releases publish helper (`scripts/publish-update-github.sh`)
- One-command GitHub release helper (`scripts/release-current-to-github.sh`)
- Auto-update flow documentation (`docs/auto-update.md`)

### Fixed
- Downgrade kernel to Linux 6.1 (more stable for compilation)
- ARM64 UEFI/GRUB boot path to load kernel from `EFI/BOOT/Image`

### Changed
- Removed X11/Xorg/Mesa from Phase 1 (graphics stack deferred to Phase 2)
- Reduced disk image size from 256M to 128M
- Simplified kernel configuration for faster builds
- Updated architecture docs to show phased approach
- Build time optimized from 60min →15-20min
- `air-kiosk` startup output now shows version + latest features only
- Dummy AI version source is centralized in `/etc/air/VERSION` (set to `v0.1.1` in this release)
- Init boot flow now mounts `/run` and `/tmp` as tmpfs and mounts `/data` when available
- Kernel cmdline now boots root with `ro` and init remounts `/` read-only
- Architecture doc now reflects immutable core, partition model, and update approach
- Runtime flag behavior is now documented (`docs/runtime-flags.md`)
- Init now follows explicit step-based startup order with service names
- Runtime logging paths now use `/run/log/air` (+ optional `/data/log/air` mirror) only
- Added runtime flag `AIR_SILENT_BOOT` (default enabled) to hide visible init logs on console
- Session now launches a minimal primary interface that shows only `Willkommen`
- ARM64 GRUB kernel args now use `quiet loglevel=0` for silent startup behavior

---

## [0.0.1] – 2026-02-10

### Added
- Project structure and documentation
- Vision document defining what Air is
- Glossary of technical terms
- Architecture overview
- Build system foundation (Buildroot external tree)
- Initial defconfig for x86_64
- Build script with dependency checking

### Changed
- Complete project restart with cleaner approach

---

## [0.0.0] – 2026-02-10

Project inception. Starting from scratch with proper documentation.

---

*Update this file with every meaningful change.*
