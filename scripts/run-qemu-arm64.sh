#!/usr/bin/env bash
set -euo pipefail

QEMU_BIN="${QEMU_BIN:-/opt/homebrew/bin/qemu-system-aarch64}"
UEFI_CODE="${UEFI_CODE:-/Users/justinkohler/Library/Containers/com.utmapp.UTM/Data/Library/Caches/qemu/edk2-aarch64-code.fd}"
DISK_IMAGE="${DISK_IMAGE:-/Users/justinkohler/Library/Containers/com.utmapp.UTM/Data/Documents/Air disk-arm64.utm/Data/75CFBA9C-C0D1-45E8-8B21-4684C7910B8A.qcow2}"
DISK_FORMAT="${DISK_FORMAT:-qcow2}"
UEFI_VARS="${UEFI_VARS:-/tmp/air-efi-vars-64m.fd}"
MEMORY_MB="${MEMORY_MB:-4096}"
CPU_COUNT="${CPU_COUNT:-4}"
RESET_EFI_VARS="${RESET_EFI_VARS:-0}"

if [[ ! -x "$QEMU_BIN" ]]; then
  echo "qemu binary not found: $QEMU_BIN" >&2
  exit 1
fi

if [[ ! -f "$UEFI_CODE" ]]; then
  echo "UEFI code file not found: $UEFI_CODE" >&2
  exit 1
fi

if [[ ! -f "$DISK_IMAGE" ]]; then
  echo "disk image not found: $DISK_IMAGE" >&2
  exit 1
fi

needs_vars_reset=0
if [[ ! -f "$UEFI_VARS" ]]; then
  needs_vars_reset=1
fi
if [[ "$RESET_EFI_VARS" == "1" ]]; then
  needs_vars_reset=1
fi
if [[ "$needs_vars_reset" == "0" ]]; then
  vars_size="$(wc -c < "$UEFI_VARS" | tr -d ' ')"
  if [[ "$vars_size" != "67108864" ]]; then
    needs_vars_reset=1
  fi
fi

if [[ "$needs_vars_reset" == "1" ]]; then
  rm -f "$UEFI_VARS"
  dd if=/dev/zero of="$UEFI_VARS" bs=1m count=64 status=none
fi

exec "$QEMU_BIN" \
  -machine virt \
  -accel hvf \
  -cpu host \
  -m "$MEMORY_MB" \
  -smp "$CPU_COUNT" \
  -nographic \
  -serial mon:stdio \
  -drive if=pflash,format=raw,readonly=on,file="$UEFI_CODE" \
  -drive if=pflash,format=raw,file="$UEFI_VARS" \
  -device virtio-blk-pci,drive=hd0 \
  -drive if=none,id=hd0,file="$DISK_IMAGE",format="$DISK_FORMAT" \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0
