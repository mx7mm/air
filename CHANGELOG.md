# Changelog

All notable changes to Air are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/).

---

## [Unreleased]

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
- Dummy AI version source is centralized in `/etc/air/VERSION` (current `v0.1.0`)
- Init boot flow now mounts `/run` and `/tmp` as tmpfs and mounts `/data` when available

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
