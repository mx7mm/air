#!/bin/bash
# Post-image script for Air OS
# 1. Creates GRUB EFI binary
# 2. Prepares EFI boot files
# 3. Runs genimage to create disk.img

set -e

BOARD_DIR="$(dirname $0)"
BR_CONFIG=""
GRUB_PLATFORM="x86_64-efi"
GRUB_MODULES_SUFFIX="x86_64-efi"
EFI_BOOT_FILE="bootx64.efi"
GRUB_CFG="${BOARD_DIR}/grub.cfg"

# Parse arguments - find genimage config
GENIMAGE_CFG=""
while getopts "c:" opt; do
    case $opt in
        c) GENIMAGE_CFG="$OPTARG" ;;
    esac
done

if [ -z "$GENIMAGE_CFG" ]; then
    GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
fi

BR_CONFIG="${BINARIES_DIR}/../.config"
if [ ! -f "$BR_CONFIG" ]; then
    echo "ERROR: Buildroot config not found at $BR_CONFIG"
    exit 1
fi

if grep -q '^BR2_aarch64=y' "$BR_CONFIG"; then
    GRUB_PLATFORM="arm64-efi"
    GRUB_MODULES_SUFFIX="arm64-efi"
    EFI_BOOT_FILE="bootaa64.efi"
    GRUB_CFG="${BOARD_DIR}/grub-arm64.cfg"
elif grep -q '^BR2_x86_64=y' "$BR_CONFIG"; then
    GRUB_PLATFORM="x86_64-efi"
    GRUB_MODULES_SUFFIX="x86_64-efi"
    EFI_BOOT_FILE="bootx64.efi"
    GRUB_CFG="${BOARD_DIR}/grub.cfg"
else
    echo "ERROR: Unsupported architecture in $BR_CONFIG"
    exit 1
fi

echo "=== Air Post-Image Script ==="
echo "BINARIES_DIR: ${BINARIES_DIR}"
echo "TARGET_DIR: ${TARGET_DIR}"
echo "HOST_DIR: ${HOST_DIR}"

# Create EFI boot directory structure
mkdir -p "${BINARIES_DIR}/EFI/BOOT"

# Ensure UEFI shell can auto-boot if it drops to shell
cat > "${BINARIES_DIR}/startup.nsh" <<EOF
\EFI\BOOT\${EFI_BOOT_FILE}
EOF

# Check if GRUB tools and modules exist
GRUB_MKIMAGE="${HOST_DIR}/bin/grub-mkimage"
if [ ! -x "$GRUB_MKIMAGE" ]; then
    echo "ERROR: grub-mkimage not found at $GRUB_MKIMAGE"
    exit 1
fi

OUTPUT_DIR="$(dirname "$BINARIES_DIR")"
GRUB_MODULES_DIR_HOST="${HOST_DIR}/lib/grub/${GRUB_MODULES_SUFFIX}"
GRUB_MODULES_DIR_TARGET="${TARGET_DIR}/usr/lib/grub/${GRUB_MODULES_SUFFIX}"
GRUB_MODULES_DIR_BUILD=""
for candidate in \
    "$OUTPUT_DIR"/build/grub2-*/build-${GRUB_MODULES_SUFFIX}/grub-core \
    "$OUTPUT_DIR"/build/grub2-*/grub-core; do
    if [ -d "$candidate" ]; then
        GRUB_MODULES_DIR_BUILD="$candidate"
        break
    fi
done

if [ -d "$GRUB_MODULES_DIR_HOST" ]; then
    GRUB_MODULES_DIR="$GRUB_MODULES_DIR_HOST"
elif [ -d "$GRUB_MODULES_DIR_TARGET" ]; then
    GRUB_MODULES_DIR="$GRUB_MODULES_DIR_TARGET"
elif [ -n "$GRUB_MODULES_DIR_BUILD" ]; then
    GRUB_MODULES_DIR="$GRUB_MODULES_DIR_BUILD"
else
    echo "ERROR: GRUB modules not found in host or target"
    echo "Tried: $GRUB_MODULES_DIR_HOST"
    echo "Tried: $GRUB_MODULES_DIR_TARGET"
    echo "Tried: $OUTPUT_DIR/build/grub2-*/build-x86_64-efi/grub-core"
    echo "Tried: $OUTPUT_DIR/build/grub2-*/grub-core"
    exit 1
fi

echo "Creating GRUB EFI binary..."

# Create GRUB EFI binary using grub-mkimage
"$GRUB_MKIMAGE" \
    -O "${GRUB_PLATFORM}" \
    -o "${BINARIES_DIR}/EFI/BOOT/${EFI_BOOT_FILE}" \
    -p /EFI/BOOT \
    -d "${GRUB_MODULES_DIR}" \
    boot linux ext2 fat part_gpt part_msdos normal efi_gop

echo "GRUB EFI binary created."

# Copy GRUB config
cp "${GRUB_CFG}" "${BINARIES_DIR}/EFI/BOOT/grub.cfg"

echo "EFI files prepared in ${BINARIES_DIR}/EFI/BOOT/"
ls -la "${BINARIES_DIR}/EFI/BOOT/"

# Create empty data partition image
echo "Creating data partition..."
DATA_IMG="${BINARIES_DIR}/data-part.ext4"
dd if=/dev/zero of="${DATA_IMG}" bs=1M count=256
mkfs.ext4 -F -L "DATA" "${DATA_IMG}"
echo "Data partition created."

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
