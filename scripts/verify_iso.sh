#!/usr/bin/env bash
set -euo pipefail

: "${OUTPUT_ISO:=out/clawops-ubuntu-autoinstall.iso}"
[[ -f "${OUTPUT_ISO}.sha256" ]] || { echo "Checksum file missing"; exit 1; }

sha256sum -c "${OUTPUT_ISO}.sha256"
echo "[verify] checksum OK"
