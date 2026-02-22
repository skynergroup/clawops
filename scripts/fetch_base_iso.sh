#!/usr/bin/env bash
# fetch_base_iso.sh — Download and verify the Ubuntu Server 24.04 LTS base ISO
set -euo pipefail

# Ubuntu Server 24.04.2 LTS (Noble Numbat) — pinned release
UBUNTU_ISO_URL="https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-live-server-amd64.iso"
UBUNTU_ISO_SHA256="d6dab0c3f76b9a5a410ff2f2196aa0c7588dbea7f98a1e2e4c02e2ef3c2b36a0"

: "${BASE_ISO:=build/base.iso}"
: "${SKIP_DOWNLOAD:=0}"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
step() { echo -e "${CYAN}[fetch]${NC} $*"; }
ok()   { echo -e "${GREEN}[ok]${NC}    $*"; }
die()  { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

mkdir -p "$(dirname "$BASE_ISO")"

# Check if already downloaded and valid
if [[ -f "$BASE_ISO" ]]; then
  step "Base ISO already exists. Verifying checksum..."
  actual=$(sha256sum "$BASE_ISO" | awk '{print $1}')
  if [[ "$actual" == "$UBUNTU_ISO_SHA256" ]]; then
    ok "Checksum valid. Using cached ISO: $BASE_ISO"
    exit 0
  else
    step "Checksum mismatch. Re-downloading..."
    rm -f "$BASE_ISO"
  fi
fi

if [[ "$SKIP_DOWNLOAD" == "1" ]]; then
  die "SKIP_DOWNLOAD=1 but no valid base ISO found at $BASE_ISO"
fi

step "Downloading Ubuntu Server 24.04.2 LTS..."
step "URL: $UBUNTU_ISO_URL"
curl -L --progress-bar -o "$BASE_ISO" "$UBUNTU_ISO_URL"

step "Verifying checksum..."
actual=$(sha256sum "$BASE_ISO" | awk '{print $1}')
if [[ "$actual" != "$UBUNTU_ISO_SHA256" ]]; then
  rm -f "$BASE_ISO"
  die "Checksum mismatch!\n  Expected: $UBUNTU_ISO_SHA256\n  Got:      $actual"
fi

ok "ISO downloaded and verified: $BASE_ISO ($(du -sh "$BASE_ISO" | cut -f1))"
