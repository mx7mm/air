#!/bin/bash
# Air Build Script
# Usage: ./scripts/build.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Find Air repo root
AIR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$HOME/air-build}"
DEFCONFIG="${AIR_DEFCONFIG:-air_defconfig}"
BUILDROOT_VERSION="2024.02"

info "Air Build System"
info "================"
info "Air repo: $AIR_ROOT"
info "Build dir: $BUILD_DIR"
info "Defconfig: $DEFCONFIG"

# Check dependencies
info "Checking dependencies..."
DEPS="git make gcc g++ wget cpio python3 rsync bc"
for dep in $DEPS; do
    if ! command -v $dep &> /dev/null; then
        error "Missing dependency: $dep"
    fi
done
info "All dependencies found."

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Get Buildroot
if [ ! -d "buildroot" ]; then
    info "Downloading Buildroot $BUILDROOT_VERSION..."
    git clone --depth 1 --branch "$BUILDROOT_VERSION" \
        https://git.buildroot.net/buildroot buildroot
else
    info "Buildroot already present."
fi

cd buildroot

# Configure external tree
export BR2_EXTERNAL="$AIR_ROOT"

# Load Air configuration
info "Loading Air configuration..."
make "${DEFCONFIG}"

# Build
info "Building Air (this will take a while)..."
make

# Done
info "================"
info "Build complete!"
info "Output image: $BUILD_DIR/buildroot/output/images/disk.img"
info ""
info "To test in QEMU:"
info "  qemu-system-x86_64 -drive file=output/images/disk.img,format=raw -m 512M"
