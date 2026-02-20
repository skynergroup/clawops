#!/usr/bin/env bash
set -euo pipefail

ISO_PATH="${1:-out/clawops-ubuntu-autoinstall.iso}"
DISK_PATH="${2:-build/vm/clawops-test.qcow2}"
LOG_PATH="${3:-artifacts/install/serial-install.log}"
TIMEOUT_SECS="${TIMEOUT_SECS:-3600}"

[[ -f "$ISO_PATH" ]] || { echo "ISO not found: $ISO_PATH"; exit 1; }
mkdir -p "$(dirname "$DISK_PATH")" "$(dirname "$LOG_PATH")"

if [[ ! -f "$DISK_PATH" ]]; then
  qemu-img create -f qcow2 "$DISK_PATH" 30G >/dev/null
fi

KVM_ARGS=()
if [[ -e /dev/kvm ]]; then
  KVM_ARGS=(-enable-kvm -cpu host)
fi

echo "[install] starting unattended install (timeout=${TIMEOUT_SECS}s)"
set +e
timeout "$TIMEOUT_SECS" qemu-system-x86_64 \
  "${KVM_ARGS[@]}" \
  -m 4096 -smp 2 \
  -cdrom "$ISO_PATH" \
  -drive file="$DISK_PATH",if=virtio,format=qcow2 \
  -boot d \
  -nographic \
  -serial mon:stdio \
  -no-reboot >"$LOG_PATH" 2>&1
rc=$?
set -e

if [[ $rc -ne 0 && $rc -ne 124 ]]; then
  echo "[install] qemu failed rc=$rc"
  tail -n 100 "$LOG_PATH" || true
  exit 1
fi

if grep -Eiq "reboot: Restarting system|Reached target Shutdown|Power down" "$LOG_PATH"; then
  echo "[install] installer reached completion/reboot marker"
  exit 0
fi

echo "[install] completion marker not found yet"
exit 2
