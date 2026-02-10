# Glossary

Technical terms used in this project, explained simply.

---

## A

### Architecture
The CPU type a system runs on. Common architectures:
- **x86_64**: Standard desktop/laptop CPUs (Intel, AMD)
- **ARM**: Mobile and embedded devices (Raspberry Pi, phones)

---

## B

### Bootloader
The first program that runs when you turn on a computer. It loads the kernel. We use **GRUB** for x86 systems.

### Buildroot
A tool that automates building a complete Linux system from source. We use it to create Air images.

### Busybox
A single binary that provides many common Unix tools (ls, cp, sh, etc.) in a very small package. Used in minimal systems.

---

## C

### Compositor
A program that combines graphical output from multiple applications into what you see on screen. In Wayland, the compositor *is* the display server. Air will have its own compositor.

---

## D

### Defconfig
Short for "default configuration". A file that contains all the build options for a system. Located in `configs/`.

---

## I

### Init
The first process that runs after the kernel boots (PID 1). It starts all other services. We use a minimal custom init.

---

## K

### Kernel
The core of the operating system. It manages hardware, memory, and processes. Air uses the **Linux kernel** but hides it from users.

---

## L

### libc
The C standard library. Every program uses it to interact with the kernel. Options:
- **glibc**: Full-featured, large (used by most Linux distros)
- **musl**: Minimal, clean, small (used by Air)

---

## M

### musl
A lightweight C library. We use it instead of glibc to keep Air small and fast.

---

## O

### Overlay (rootfs-overlay)
Files that get copied on top of the base system. Used to add custom configurations, scripts, and branding.

---

## R

### Root Filesystem (rootfs)
The main filesystem of the OS containing all programs, libraries, and data. Mounted at `/`.

---

## W

### Wayland
A modern display protocol that replaces the 30-year-old X11. More secure, simpler, faster. Air uses Wayland.

### wlroots
A library for building Wayland compositors. We'll use it to create Air's compositor.

---

## X

### X11 / Xorg
The old display system for Linux. Complex, legacy, insecure. Air does **not** use X11.

---

*Add new terms as they come up. Keep explanations simple.*
