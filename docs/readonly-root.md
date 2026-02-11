# Read-Only Root Filesystem

## Overview

Air implements a read-only root filesystem for enhanced immutability, security, and reliability. This document explains the implementation and how to verify it works correctly.

## Implementation

### 1. Kernel Configuration

The root filesystem is mounted as read-only via the `ro` kernel parameter in GRUB:

**x86_64** (`board/air/grub.cfg`):
```
linux /boot/bzImage root=PARTUUID=... ro rootwait ...
```

**ARM64** (`board/air/grub-arm64.cfg`):
```
linux /boot/Image root=PARTUUID=... ro rootwait ...
```

### 2. Tmpfs Overlays

Since many system services need write access to specific directories, the init script mounts tmpfs (RAM-based temporary filesystems) over directories that require write access:

**Mounted tmpfs directories** (in `board/air/rootfs-overlay/etc/init.d/rcS`):
- `/tmp` - Temporary files
- `/run` - Runtime variable data
- `/var` - Variable data (logs, cache, etc.)

The init script also creates necessary subdirectories within `/var`:
- `/var/log` - System logs
- `/var/tmp` - Temporary files
- `/var/cache` - Application caches
- `/var/lib` - Application state
- `/var/lock` - Lock files
- `/var/spool` - Spool directories

### 3. Boot Sequence

1. Kernel boots with `ro` parameter, mounting root as read-only
2. Init system starts (`/sbin/init`)
3. `rcS` script runs, mounting:
   - Essential filesystems (`/proc`, `/sys`, `/dev`)
   - Tmpfs overlays for writable directories
4. System continues normal boot

## Benefits

1. **Immutability**: Core system files cannot be modified at runtime
2. **Security**: Reduces attack surface by preventing unauthorized file modifications
3. **Reliability**: System always boots to a known-good state
4. **Data Loss Prevention**: Logs and temporary data are clearly separated from persistent state

## Verification

Run the verification script after boot:

```bash
/usr/bin/air-verify-readonly
```

This script checks:
- Root filesystem is mounted read-only
- Required tmpfs mounts are present
- Write operations fail on root
- Write operations succeed on tmpfs mounts

### Manual Verification

Check mount status:
```bash
mount | grep "on / "          # Should show "ro" option
mount | grep tmpfs            # Should show /tmp, /run, /var
```

Test write operations:
```bash
touch /.test              # Should fail with "Read-only file system"
touch /tmp/.test          # Should succeed
touch /var/log/.test      # Should succeed
```

## Caveats

- **Persistence**: Data written to `/tmp`, `/run`, and `/var` is lost on reboot
- **Memory Usage**: Tmpfs mounts consume RAM; size limits may be needed for production
- **Logging**: System logs are not persistent across reboots
- **Updates**: System updates require remounting root as read-write or updating the disk image

## Future Enhancements

For production use, consider:

1. **Persistent Logging**: Mount a separate partition for `/var/log`
2. **Size Limits**: Add size limits to tmpfs mounts to prevent memory exhaustion
3. **Overlay Filesystem**: Use overlayfs for more sophisticated read-only/read-write layering
4. **Configuration Management**: Implement a mechanism for persistent configuration changes
