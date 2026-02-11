# Changelog

All notable changes to Air are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/).

---

## [Unreleased]

### Added
- /data partition for persistent data storage
- S01mount-data init script to mount /data at boot
- Writable directories structure in /data (/data/var, /data/home, /data/tmp, /data/log)
- MIT License
- Security policy (SECURITY.md)
- Contributing guidelines
- GitHub issue templates (bug, feature request)
- Pull request template
- GitHub Actions CI/CD workflow for automated builds
- Professional documentation for collaborators
- Read-only root filesystem support via `ro` kernel parameter
- air-verify-readonly script for validating immutable root configuration

### Fixed
- Downgrade kernel to Linux 6.1 (more stable for compilation)

### Changed
- Updated disk image layout to include /data partition (256M)
- Modified GRUB configuration to pass /data partition UUID to kernel
- Enhanced shutdown sequence to properly sync and unmount /data
- Removed X11/Xorg/Mesa from Phase 1 (graphics stack deferred to Phase 2)
- Reduced disk image size from 256M to 128M
- Simplified kernel configuration for faster builds
- Updated architecture docs to show phased approach
- Build time optimized from 60min →15-20min
- Adapted init process for immutability - root filesystem now mounted read-only
- Init scripts no longer write to root filesystem during boot
- Temporary files relocated to /data partition or tmpfs mounts

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
