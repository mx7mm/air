# Architecture

How Air is structured, from hardware to user interface.

## System Layers

```
┌─────────────────────────────────────┐
│     Air Apps (Phase 2+)             │  <- What users will see
├─────────────────────────────────────┤
│  Air Compositor (Phase 2+)          │  <- Window management
├─────────────────────────────────────┤
│  Busybox Init + Kiosk (Phase 1)     │  <- Boot and testing
├─────────────────────────────────────┤
│        musl libc                    │  <- System library
├─────────────────────────────────────┤
│        Linux Kernel                 │  <- Hardware interface
├─────────────────────────────────────┤
│         Hardware                    │  <- Physical device
└─────────────────────────────────────┘
```

**Phase 1 (Current):** Bootable immutable core + kiosk shell  
**Phase 2:** Add Wayland + Compositor  
**Phase 3:** Add Apps + Cloud services

## Components

### Linux Kernel
- Handles hardware drivers, memory, processes
- Users never interact with it directly
- Configured for minimal footprint

### musl libc
- Lightweight C library
- Replaces glibc (smaller, cleaner)
- Every program links against it

### Wayland + wlroots
- Modern graphics stack
- wlroots provides building blocks for our compositor
- Replaces legacy X11

### Air Compositor
- **Our code** - the first custom component
- Manages windows, input, display
- Enforces Air visual rules

### Air Apps
- Full-screen applications
- Web-based (Chromium runtime) or native
- Delivered and updated from the cloud

## Boot Sequence (Current)

```
1. BIOS/UEFI
   ↓
2. GRUB (bootloader)
   ↓
3. Linux Kernel
   ↓
4. Air Init (PID 1)
   ↓
5. Kiosk Session (air-session -> air-kiosk)
   ↓
6. Debug shell only when explicitly enabled
```

No login. Straight to Air. Shell is debug-only fallback.

## Base Services (v0.3)

The init script now uses a deterministic service order from:

`/etc/air/service-order.conf`

This defines explicit boot steps (mounts, logging, identity, checks, session launch) and avoids implicit startup behavior.

Runtime logs are written to:

- `/run/log/air` (volatile)
- `/data/log/air` (persistent mirror, when available)

See `docs/base-services.md` for full details.

## Immutable Core Model (v0.2)

Air now uses an immutable-first boot model:

- Root filesystem boots with `ro` kernel flag.
- Init mounts volatile state on tmpfs:
  - `/run`
  - `/tmp`
- Persistent writable state is isolated to `/data`.
- Optional immutability smoke check verifies root write behavior.

This keeps system binaries and base config immutable while still allowing runtime state and persistence where intended.

## Partition Model (Current)

The generated disk image (`disk.img`) uses GPT with:

1. `boot` (EFI FAT)  
   UEFI boot files and GRUB configuration.
2. `rootfs` (ext4)  
   Main system image, mounted read-only at runtime.
3. `data` (ext4)  
   Persistent writable partition, mounted at `/data`.

Current fixed sizes:

- `boot`: 128 MiB
- `rootfs`: 768 MiB
- `data`: 512 MiB

Current fixed PARTUUIDs:

- `rootfs`: `8b4b0b87-2f1b-4ea9-9f50-0fba0d4b5ac0`
- `data`: `4fd2ec57-5fd8-4a77-8f9e-7ad40f6f9489`

Mount behavior is implemented in `board/air/rootfs-overlay/etc/init.d/rcS`.

## Bootloader Policy (Current)

- Default boot entry is `Air` with hidden menu and silent kernel arguments.
- A secondary `Air Recovery` GRUB entry is provided for emergency shell boot.
- Normal path targets direct transition into primary interface (`Willkommen`).

## Update Mechanism (Current vs Target)

Current (v0.2):
- Buildroot generates a full disk image.
- Updates are image-based replacement/reflash in current dev workflow.
- Runtime does not include transactional OTA yet.

Target (future):
- A/B or equivalent atomic update strategy.
- Verified image handoff and rollback support.
- Cloud-orchestrated release channels.

## Directory Structure (on device)

```
/
├── bin/            # Core binaries
├── lib/            # Libraries (musl, etc.)
├── etc/            # Configuration
├── data/           # Persistent writable state
├── run/            # Volatile runtime state (tmpfs)
├── tmp/            # Volatile temp state (tmpfs)
├── usr/
│   └── share/air/  # Air-specific assets
└── var/            # Runtime-managed paths (minimal in phase 1)
```

## Build System

We use **Buildroot** to compile everything from source:

```
Air Repo
├── configs/air_defconfig    # Build configuration
├── board/air/               # Board-specific files
│   ├── rootfs-overlay/      # Files copied to rootfs
│   └── genimage.cfg         # Disk image layout
└── scripts/build.sh         # Build entry point
```

Buildroot downloads, compiles, and packages:
- Linux kernel
- musl
- Busybox
- Our custom packages

Output: A bootable disk image.

## Network Architecture (Future)

```
┌──────────────┐        ┌──────────────┐
│  Air Device  │◄──────►│  Air Cloud   │
└──────────────┘        └──────────────┘
                              │
                        ┌─────┴─────┐
                        │           │
                   App Store    User Data
                   Updates      Sync
```

All devices connect to Air Cloud for:
- App delivery
- System updates
- User data synchronization
- Device management

---

*This document evolves as we build.*
