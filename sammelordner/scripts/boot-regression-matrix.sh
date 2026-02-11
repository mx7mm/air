#!/usr/bin/env bash
set -euo pipefail

QEMU_BIN="${QEMU_BIN:-/opt/homebrew/bin/qemu-system-aarch64}"
UEFI_CODE="${UEFI_CODE:-/Users/justinkohler/Library/Containers/com.utmapp.UTM/Data/Library/Caches/qemu/edk2-aarch64-code.fd}"
DISK_IMAGE="${DISK_IMAGE:-/Users/justinkohler/Documents/Air/disk.img}"
DISK_FORMAT="${DISK_FORMAT:-raw}"
ATTEMPTS_PER_PROFILE="${ATTEMPTS_PER_PROFILE:-3}"
BOOT_TIMEOUT_SEC="${BOOT_TIMEOUT_SEC:-45}"
BOOT_MATRIX_PROFILES="${BOOT_MATRIX_PROFILES:-baseline,constrained}"
LOG_DIR="${LOG_DIR:-/tmp/air-boot-matrix}"

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

mkdir -p "$LOG_DIR"

profile_cpus() {
  case "$1" in
    baseline) echo "4" ;;
    constrained) echo "2" ;;
    *) echo "unknown profile: $1" >&2; exit 1 ;;
  esac
}

profile_mem() {
  case "$1" in
    baseline) echo "4096" ;;
    constrained) echo "2048" ;;
    *) echo "unknown profile: $1" >&2; exit 1 ;;
  esac
}

run_once() {
  local profile="$1"
  local attempt="$2"
  local cpus memory vars_file log_file qemu_pid pass

  cpus="$(profile_cpus "$profile")"
  memory="$(profile_mem "$profile")"
  vars_file="${LOG_DIR}/efi-vars-${profile}-${attempt}.fd"
  log_file="${LOG_DIR}/boot-${profile}-${attempt}.log"
  pass="0"

  rm -f "$vars_file" "$log_file"
  dd if=/dev/zero of="$vars_file" bs=1m count=64 status=none

  "$QEMU_BIN" \
    -machine virt \
    -accel hvf \
    -cpu host \
    -m "$memory" \
    -smp "$cpus" \
    -nographic \
    -serial mon:stdio \
    -drive if=pflash,format=raw,readonly=on,file="$UEFI_CODE" \
    -drive if=pflash,format=raw,file="$vars_file" \
    -device virtio-blk-pci,drive=hd0 \
    -drive if=none,id=hd0,file="$DISK_IMAGE",format="$DISK_FORMAT" \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0 >"$log_file" 2>&1 &
  qemu_pid="$!"

  for _ in $(seq 1 "$BOOT_TIMEOUT_SEC"); do
    if rg -q "air-ai>" "$log_file"; then
      pass="1"
      break
    fi
    if ! kill -0 "$qemu_pid" 2>/dev/null; then
      break
    fi
    sleep 1
  done

  if kill -0 "$qemu_pid" 2>/dev/null; then
    kill "$qemu_pid" 2>/dev/null || true
    sleep 1
    kill -9 "$qemu_pid" 2>/dev/null || true
  fi
  wait "$qemu_pid" 2>/dev/null || true

  if [[ "$pass" == "1" ]] && ! rg -q "Kernel panic|Failed to boot both default and fallback entries|can't find command" "$log_file"; then
    echo "PASS ${profile} attempt=${attempt} log=${log_file}"
    return 0
  fi

  echo "FAIL ${profile} attempt=${attempt} log=${log_file}" >&2
  return 1
}

total=0
failed=0
IFS=',' read -r -a profiles <<< "$BOOT_MATRIX_PROFILES"

for profile in "${profiles[@]}"; do
  for attempt in $(seq 1 "$ATTEMPTS_PER_PROFILE"); do
    total=$((total + 1))
    if ! run_once "$profile" "$attempt"; then
      failed=$((failed + 1))
    fi
  done
done

echo "SUMMARY total=${total} failed=${failed} logs=${LOG_DIR}"
if [[ "$failed" -gt 0 ]]; then
  exit 1
fi

