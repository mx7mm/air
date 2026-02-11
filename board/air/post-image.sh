#!/usr/bin/env bash

set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

BOARD_DIR="$(cd "$(dirname "$0")" && pwd)"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"

while getopts "c:" opt; do
    case "$opt" in
        c) GENIMAGE_CFG="$OPTARG" ;;
        *) die "Unsupported option: -$opt" ;;
    esac
done

: "${BINARIES_DIR:?BINARIES_DIR is not set}"
: "${TARGET_DIR:?TARGET_DIR is not set}"
: "${HOST_DIR:?HOST_DIR is not set}"

BR_CONFIG=""
for candidate in \
    "${BR2_CONFIG:-}" \
    "${BINARIES_DIR}/../.config" \
    "${BINARIES_DIR}/../../.config"; do
    if [ -n "$candidate" ] && [ -f "$candidate" ]; then
        BR_CONFIG="$candidate"
        break
    fi
done
[ -n "$BR_CONFIG" ] || die "Buildroot config not found."

if grep -q '^BR2_aarch64=y' "$BR_CONFIG"; then
    GRUB_PLATFORM="arm64-efi"
    GRUB_MODULES_SUFFIX="arm64-efi"
    EFI_BOOT_FILE="bootaa64.efi"
    KERNEL_IMAGE_NAME="Image"
    GRUB_CFG="${BOARD_DIR}/grub-arm64.cfg"
elif grep -q '^BR2_x86_64=y' "$BR_CONFIG"; then
    GRUB_PLATFORM="x86_64-efi"
    GRUB_MODULES_SUFFIX="x86_64-efi"
    EFI_BOOT_FILE="bootx64.efi"
    KERNEL_IMAGE_NAME="bzImage"
    GRUB_CFG="${BOARD_DIR}/grub.cfg"
else
    die "Unsupported architecture in $BR_CONFIG"
fi

GRUB_MKIMAGE="${HOST_DIR}/bin/grub-mkimage"
[ -x "$GRUB_MKIMAGE" ] || die "grub-mkimage not found at $GRUB_MKIMAGE"

OUTPUT_DIR="$(dirname "$BINARIES_DIR")"
GRUB_MODULES_DIR=""
shopt -s nullglob
for candidate in \
    "${HOST_DIR}/lib/grub/${GRUB_MODULES_SUFFIX}" \
    "${TARGET_DIR}/usr/lib/grub/${GRUB_MODULES_SUFFIX}" \
    "${OUTPUT_DIR}"/build/grub2-*/build-"${GRUB_MODULES_SUFFIX}"/grub-core \
    "${OUTPUT_DIR}"/build/grub2-*/grub-core; do
    if [ -d "$candidate" ]; then
        GRUB_MODULES_DIR="$candidate"
        break
    fi
done
shopt -u nullglob
[ -n "$GRUB_MODULES_DIR" ] || die "GRUB modules not found for ${GRUB_MODULES_SUFFIX}"

echo "=== Air Post-Image Script ==="
echo "BINARIES_DIR: ${BINARIES_DIR}"
echo "TARGET_DIR: ${TARGET_DIR}"
echo "HOST_DIR: ${HOST_DIR}"

mkdir -p "${BINARIES_DIR}/EFI/BOOT"
printf '\\EFI\\BOOT\\%s\n' "${EFI_BOOT_FILE}" > "${BINARIES_DIR}/startup.nsh"

"$GRUB_MKIMAGE" \
    -O "${GRUB_PLATFORM}" \
    -o "${BINARIES_DIR}/EFI/BOOT/${EFI_BOOT_FILE}" \
    -p /EFI/BOOT \
    -d "${GRUB_MODULES_DIR}" \
    boot linux ext2 fat part_gpt part_msdos normal efi_gop search test

cp "${GRUB_CFG}" "${BINARIES_DIR}/EFI/BOOT/grub.cfg"

KERNEL_IMAGE_SRC="${BINARIES_DIR}/${KERNEL_IMAGE_NAME}"
[ -f "${KERNEL_IMAGE_SRC}" ] || die "Kernel image not found: ${KERNEL_IMAGE_SRC}"
cp "${KERNEL_IMAGE_SRC}" "${BINARIES_DIR}/EFI/BOOT/${KERNEL_IMAGE_NAME}"

# Build an empty ext4 image for /data without requiring genext2fs.
DATA_IMAGE="${BINARIES_DIR}/data.ext4"
rm -f "${DATA_IMAGE}"
dd if=/dev/zero of="${DATA_IMAGE}" bs=1M count=512 status=none
"${HOST_DIR}/sbin/mkfs.ext4" -F -L data "${DATA_IMAGE}" >/dev/null 2>&1 || \
    /sbin/mkfs.ext4 -F -L data "${DATA_IMAGE}" >/dev/null 2>&1 || \
    mkfs.ext4 -F -L data "${DATA_IMAGE}" >/dev/null 2>&1 || \
    die "mkfs.ext4 not found"

echo "EFI files prepared in ${BINARIES_DIR}/EFI/BOOT/"
ls -la "${BINARIES_DIR}/EFI/BOOT/"

GENIMAGE_TMP="${BINARIES_DIR}/../genimage.tmp"
rm -rf "${GENIMAGE_TMP}"

GENIMAGE_BIN="${HOST_DIR}/bin/genimage"
if [ ! -x "${GENIMAGE_BIN}" ] || [ ! -s "${GENIMAGE_BIN}" ]; then
    GENIMAGE_BIN="$(command -v genimage || true)"
fi
[ -n "${GENIMAGE_BIN}" ] && [ -x "${GENIMAGE_BIN}" ] && [ -s "${GENIMAGE_BIN}" ] || die "genimage not found or invalid"

"${GENIMAGE_BIN}" \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"

echo "=== Disk image created: ${BINARIES_DIR}/disk.img ==="
