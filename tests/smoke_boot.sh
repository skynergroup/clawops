#!/usr/bin/env bash
set -euo pipefail

ISO_PATH="${1:-out/clawops-ubuntu-autoinstall.iso}"

[[ -f "$ISO_PATH" ]] || { echo "[smoke] ISO not found: $ISO_PATH"; exit 1; }

echo "[smoke] checking grub autoinstall args in ISO"
if ! 7z e -so "$ISO_PATH" boot/grub/grub.cfg 2>/dev/null | grep -q "autoinstall ds=nocloud"; then
  echo "[smoke] autoinstall args not found in grub.cfg"
  exit 1
fi

echo "[smoke] grub autoinstall args detected"

if command -v qemu-system-x86_64 >/dev/null; then
  echo "[smoke] running short headless QEMU boot probe"
  set +e
  timeout 45 qemu-system-x86_64 \
    -m 2048 \
    -cdrom "$ISO_PATH" \
    -boot d \
    -nographic \
    -serial mon:stdio \
    -no-reboot >/tmp/clawops-qemu-smoke.log 2>&1
  rc=$?
  set -e
  if [[ $rc -ne 0 && $rc -ne 124 ]]; then
    echo "[smoke] qemu boot probe failed (rc=$rc)"
    tail -n 60 /tmp/clawops-qemu-smoke.log || true
    exit 1
  fi
  echo "[smoke] qemu boot probe completed"
else
  echo "[smoke] qemu-system-x86_64 not found; skipped runtime boot probe"
fi

echo "[smoke] PASS"
