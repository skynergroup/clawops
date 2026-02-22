#!/usr/bin/env bash
# verify_iso.sh — Verify a ClawOps ISO against its .sha256 file
set -euo pipefail

ISO="${1:-out/clawops-1.0-amd64.iso}"
CHECKSUM_FILE="${ISO%.iso}.sha256"

[[ -f "$ISO" ]] || { echo "ISO not found: $ISO" >&2; exit 1; }
[[ -f "$CHECKSUM_FILE" ]] || { echo "Checksum file not found: $CHECKSUM_FILE" >&2; exit 1; }

echo "Verifying $ISO..."
sha256sum -c "$CHECKSUM_FILE" && echo "OK: Checksum valid." || { echo "FAIL: Checksum mismatch." >&2; exit 1; }
