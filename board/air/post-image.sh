#!/bin/bash
# Post-image script for Air OS
# 1. Prepares EFI boot files
# 2. Runs genimage to create disk.img

set -e

BOARD_DIR="$(dirname $0)"

# Parse arguments - find genimage config
GENIMAGE_CFG=""
while getopts "c:" opt; do
    case $opt in
        c) GENIMAGE_CFG="$OPTARG" ;;
    esac
done

echo "=== Air Post-Image Script ==="
echo "BINARIES_DIR: ${BINARIES_DIR}"
echo "TARGET_DIR: ${TARGET_DIR}"
echo "HOST_DIR: ${HOST_DIR}"

# Create EFI boot directory structure
mkdir -p "${BINARIES_DIR}/EFI/BOOT"

# Find and copy GRUB EFI binary
GRUB_EFI=""
for src in \
    "${BINARIES_DIR}/efi-part/EFI/BOOT/bootx64.efi" \
    "${HOST_DIR}/lib/grub/x86_64-efi/monolithic/grubx64.efi" \
    "${HOST_DIR}/lib/grub/x86_64-efi/grub.efi" \
    "${BINARIES_DIR}/../build/grub2-*/grub-core/grub.efi"
do
    if [ -f "$src" ]; then
        GRUB_EFI="$src"
        break
    fi
done

if [ -n "$GRUB_EFI" ]; then
    cp "$GRUB_EFI" "${BINARIES_DIR}/EFI/BOOT/bootx64.efi"
    echo "Copied GRUB EFI from $GRUB_EFI"
else
    echo "ERROR: GRUB EFI binary not found!"
    echo "Searched in:"
    echo "  ${HOST_DIR}/lib/grub/x86_64-efi/"
    ls -la "${HOST_DIR}/lib/grub/" 2>/dev/null || echo "  (directory not found)"
    exit 1
fi

# Copy GRUB config
cp "${BOARD_DIR}/grub.cfg" "${BINARIES_DIR}/EFI/BOOT/grub.cfg"

echo "EFI files prepared in ${BINARIES_DIR}/EFI/BOOT/"
ls -la "${BINARIES_DIR}/EFI/BOOT/"

# Run genimage
GENIMAGE_TMP="${BINARIES_DIR}/../genimage.tmp"
rm -rf "${GENIMAGE_TMP}"

genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"

echo "=== Disk image created: ${BINARIES_DIR}/disk.img ==="
