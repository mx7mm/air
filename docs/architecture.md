# Architecture

How Air is structured, from hardware to user interface.

## System Layers

```
┌─────────────────────────────────────┐
│           Air Apps                  │  ← What users see
├─────────────────────────────────────┤
│        Air Compositor               │  ← Window management, rendering
├─────────────────────────────────────┤
│       Wayland + wlroots             │  ← Graphics protocol
├─────────────────────────────────────┤
│        musl libc                    │  ← System library
├─────────────────────────────────────┤
│        Linux Kernel                 │  ← Hardware interface
├─────────────────────────────────────┤
│         Hardware                    │  ← Physical device
└─────────────────────────────────────┘
```

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
- **Our code** – the first custom component
- Manages windows, input, display
- Enforces Air's visual rules (no window decorations, no minimize, etc.)

### Air Apps
- Full-screen applications
- Web-based (Chromium runtime) or native
- Delivered and updated from the cloud

## Boot Sequence

```
1. BIOS/UEFI
   ↓
2. GRUB (bootloader)
   ↓
3. Linux Kernel
   ↓
4. Air Init (PID 1)
   ↓
5. Air Compositor
   ↓
6. Air Shell (home screen)
```

No login. No shell. Straight to Air.

## Directory Structure (on device)

```
/
├── bin/            # Core binaries
├── lib/            # Libraries (musl, etc.)
├── etc/            # Configuration
├── usr/
│   └── share/air/  # Air-specific assets
└── var/
    └── air/        # Runtime data
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
