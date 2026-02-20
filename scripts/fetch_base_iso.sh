#!/usr/bin/env bash
set -euo pipefail

mkdir -p build
: "${BASE_ISO_URL:?BASE_ISO_URL is required}"
: "${BASE_ISO_SHA256:?BASE_ISO_SHA256 is required}"
: "${BASE_ISO:=build/base.iso}"

echo "[fetch] URL: $BASE_ISO_URL"
curl -fL --retry 3 --retry-delay 2 "$BASE_ISO_URL" -o "$BASE_ISO"

echo "${BASE_ISO_SHA256}  ${BASE_ISO}" | sha256sum -c -
echo "[fetch] base ISO verified"
