#!/usr/bin/env bash
set -euo pipefail

mkdir -p build
: "${BASE_ISO_URL:?BASE_ISO_URL is required}"
: "${BASE_ISO:=build/base.iso}"

ISO_NAME="$(basename "$BASE_ISO_URL")"
SUMS_URL="$(dirname "$BASE_ISO_URL")/SHA256SUMS"

if [[ -z "${BASE_ISO_SHA256:-}" ]]; then
  echo "[fetch] BASE_ISO_SHA256 not set, resolving from $SUMS_URL"
  BASE_ISO_SHA256="$(curl -fsSL "$SUMS_URL" | awk -v n="$ISO_NAME" '$2=="*"n {print $1; exit}')"
fi

[[ -n "${BASE_ISO_SHA256:-}" ]] || { echo "[fetch] could not resolve checksum for $ISO_NAME"; exit 1; }

echo "[fetch] URL: $BASE_ISO_URL"
curl -fL --retry 3 --retry-delay 2 "$BASE_ISO_URL" -o "$BASE_ISO"

echo "${BASE_ISO_SHA256}  ${BASE_ISO}" | sha256sum -c -
echo "[fetch] base ISO verified"
