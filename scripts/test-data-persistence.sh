#!/usr/bin/env bash
set -euo pipefail

QEMU_BIN="${QEMU_BIN:-/opt/homebrew/bin/qemu-system-aarch64}"
DISK_IMAGE="${DISK_IMAGE:-/Users/justinkohler/Documents/Air/disk.img}"
DISK_FORMAT="${DISK_FORMAT:-raw}"
KERNEL_IMAGE="${KERNEL_IMAGE:-/Users/justinkohler/Documents/Air/Image-arm64}"
ROOT_PARTUUID="${ROOT_PARTUUID:-8b4b0b87-2f1b-4ea9-9f50-0fba0d4b5ac0}"
CPU_COUNT="${CPU_COUNT:-2}"
MEMORY_MB="${MEMORY_MB:-2048}"
STEP_TIMEOUT_SEC="${STEP_TIMEOUT_SEC:-60}"
LOG_FILE="${LOG_FILE:-/tmp/air-data-persistence.log}"
MARKER="persist-$(date +%s)"

if [[ ! -x "$QEMU_BIN" ]]; then
  echo "qemu binary not found: $QEMU_BIN" >&2
  exit 1
fi
if [[ ! -f "$DISK_IMAGE" ]]; then
  echo "disk image not found: $DISK_IMAGE" >&2
  exit 1
fi
if [[ ! -f "$KERNEL_IMAGE" ]]; then
  echo "kernel image not found: $KERNEL_IMAGE" >&2
  exit 1
fi
if ! command -v expect >/dev/null 2>&1; then
  echo "expect not found" >&2
  exit 1
fi

: > "$LOG_FILE"

export QEMU_BIN DISK_IMAGE DISK_FORMAT KERNEL_IMAGE ROOT_PARTUUID CPU_COUNT MEMORY_MB STEP_TIMEOUT_SEC LOG_FILE MARKER

expect <<'EOF'
set timeout $env(STEP_TIMEOUT_SEC)
log_file -a $env(LOG_FILE)

spawn $env(QEMU_BIN) \
  -machine virt \
  -accel hvf \
  -cpu host \
  -m $env(MEMORY_MB) \
  -smp $env(CPU_COUNT) \
  -nographic \
  -serial mon:stdio \
  -kernel $env(KERNEL_IMAGE) \
  -append "root=PARTUUID=$env(ROOT_PARTUUID) ro rootwait console=ttyAMA0 AIR_DEBUG=1 AIR_IMMUTABILITY_CHECK=1" \
  -device virtio-blk-pci,drive=hd0 \
  -drive if=none,id=hd0,file=$env(DISK_IMAGE),format=$env(DISK_FORMAT) \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0

expect {
  "air-ai>" {}
  timeout { puts "FAIL: did not reach kiosk prompt on first boot"; exit 11 }
}
send "exit\r"
expect {
  "~ #" {}
  timeout { puts "FAIL: did not reach debug shell on first boot"; exit 12 }
}

send "echo '$env(MARKER)' > /data/persist-test\r"
send "sync\r"
send "cat /data/persist-test\r"
send "reboot -f\r"

expect {
  "air-ai>" {}
  timeout { puts "FAIL: did not reach kiosk prompt after reboot"; exit 13 }
}
send "exit\r"
expect {
  "~ #" {}
  timeout { puts "FAIL: did not reach debug shell after reboot"; exit 14 }
}
send "cat /data/persist-test\r"
expect {
  "$env(MARKER)" {}
  timeout { puts "FAIL: marker not persisted across reboot"; exit 15 }
}

send "\001x"
expect eof
EOF

echo "PASS: /data persistence verified across reboot"
echo "marker=$MARKER"
echo "log=$LOG_FILE"
