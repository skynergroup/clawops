#!/usr/bin/env bash
# checksum.sh — Generate SHA256 checksum for the output ISO
set -euo pipefail

ISO="${1:-out/clawops-1.0-amd64.iso}"

[[ -f "$ISO" ]] || { echo "File not found: $ISO" >&2; exit 1; }

CHECKSUM_FILE="${ISO%.iso}.sha256"
sha256sum "$ISO" > "$CHECKSUM_FILE"

echo "SHA256: $(cat "$CHECKSUM_FILE")"
echo "Written to: $CHECKSUM_FILE"
