#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

AIR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$HOME/air-build}"
DEFCONFIG="${AIR_DEFCONFIG:-air_defconfig}"
BUILDROOT_VERSION="2024.02"
BUILDROOT_AUTO_SYNC="${BUILDROOT_AUTO_SYNC:-1}"

info "Air Build System"
info "================"
info "Air repo: $AIR_ROOT"
info "Build dir: $BUILD_DIR"
info "Defconfig: $DEFCONFIG"

[ "$(uname -s)" = "Linux" ] || die "Unsupported host OS: $(uname -s). Run this build on Linux (local VM or SSH host)."

info "Checking dependencies..."
for dep in git make gcc g++ cpio python3 rsync bc; do
    command -v "$dep" >/dev/null 2>&1 || die "Missing dependency: $dep"
done

if command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget"
elif command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl"
else
    die "Missing dependency: wget or curl"
fi

gcc --version 2>/dev/null | head -n 1 | grep -qi 'gcc' || die "GNU gcc is required. Detected a non-GNU 'gcc'."
info "Using downloader: $DOWNLOADER"
info "All dependencies found."

mkdir -p "$BUILD_DIR"

if [ ! -d "$BUILD_DIR/buildroot" ]; then
    info "Downloading Buildroot $BUILDROOT_VERSION..."
    git clone --depth 1 --branch "$BUILDROOT_VERSION" https://git.buildroot.net/buildroot "$BUILD_DIR/buildroot"
else
    info "Buildroot already present."
    [ -d "$BUILD_DIR/buildroot/.git" ] || die "Existing buildroot directory is not a git repository: $BUILD_DIR/buildroot"

    CURRENT_TAG="$(git -C "$BUILD_DIR/buildroot" describe --tags --exact-match 2>/dev/null || true)"
    if [ "$CURRENT_TAG" != "$BUILDROOT_VERSION" ]; then
        warn "Buildroot is not pinned to $BUILDROOT_VERSION (current: ${CURRENT_TAG:-unknown})."
        [ "$BUILDROOT_AUTO_SYNC" = "1" ] || die "Set BUILDROOT_AUTO_SYNC=1 to auto-sync Buildroot to $BUILDROOT_VERSION."
        [ -z "$(git -C "$BUILD_DIR/buildroot" status --porcelain)" ] || die "Local changes detected in $BUILD_DIR/buildroot; cannot auto-sync safely."

        info "Syncing Buildroot to $BUILDROOT_VERSION..."
        git -C "$BUILD_DIR/buildroot" fetch --depth 1 origin tag "$BUILDROOT_VERSION"
        git -C "$BUILD_DIR/buildroot" checkout --detach -q "tags/$BUILDROOT_VERSION"
    fi
fi

cd "$BUILD_DIR/buildroot"
export BR2_EXTERNAL="$AIR_ROOT"

info "Loading Air configuration..."
make "$DEFCONFIG"

info "Building Air (this will take a while)..."
make

info "================"
info "Build complete!"
info "Output image: $BUILD_DIR/buildroot/output/images/disk.img"
info ""
if [ "$DEFCONFIG" = "air_arm64_defconfig" ]; then
    info "To test in QEMU (ARM64/UEFI):"
    info "  qemu-system-aarch64 -machine virt -cpu cortex-a57 -m 1024 \\"
    info "    -bios /path/to/QEMU_EFI.fd \\"
    info "    -drive file=output/images/disk.img,format=raw,if=virtio"
else
    info "To test in QEMU (x86_64):"
    info "  qemu-system-x86_64 -drive file=output/images/disk.img,format=raw -m 512M"
fi
