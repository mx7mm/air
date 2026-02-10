#!/bin/bash
# Post-image script for Air OS
# 1. Creates GRUB EFI binary
# 2. Prepares EFI boot files
# 3. Runs genimage to create disk.img

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

# Check if GRUB modules exist
GRUB_MODULES_DIR="${HOST_DIR}/lib/grub/x86_64-efi"
if [ ! -d "$GRUB_MODULES_DIR" ]; then
    echo "ERROR: GRUB modules not found at $GRUB_MODULES_DIR"
    exit 1
fi

echo "Creating GRUB EFI binary..."

# Create GRUB EFI binary using grub-mkimage
"${HOST_DIR}/bin/grub-mkimage" \
    -O x86_64-efi \
    -o "${BINARIES_DIR}/EFI/BOOT/bootx64.efi" \
    -p /EFI/BOOT \
    -d "${GRUB_MODULES_DIR}" \
    boot linux ext2 fat part_gpt part_msdos normal efi_gop

echo "GRUB EFI binary created."

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
