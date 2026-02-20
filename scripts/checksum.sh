#!/usr/bin/env bash
set -euo pipefail

: "${OUTPUT_ISO:=out/clawops-ubuntu-autoinstall.iso}"

[[ -f "$OUTPUT_ISO" ]] || { echo "ISO not found: $OUTPUT_ISO"; exit 1; }
sha256sum "$OUTPUT_ISO" > "${OUTPUT_ISO}.sha256"
echo "[checksum] wrote ${OUTPUT_ISO}.sha256"
