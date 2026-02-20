SHELL := /bin/bash

BASE_ISO_URL ?= https://releases.ubuntu.com/24.04/ubuntu-24.04.4-live-server-amd64.iso
# Optional: if empty, fetch_base_iso.sh resolves checksum from SHA256SUMS.
BASE_ISO_SHA256 ?=
BASE_ISO ?= build/base.iso
OUTPUT_ISO ?= out/clawops-ubuntu-autoinstall.iso

export BASE_ISO_URL BASE_ISO_SHA256 BASE_ISO OUTPUT_ISO

.PHONY: deps fetch-base build checksum verify clean

deps:
	@command -v xorriso >/dev/null || (echo "xorriso missing" && exit 1)
	@command -v 7z >/dev/null || (echo "p7zip missing" && exit 1)
	@command -v rsync >/dev/null || (echo "rsync missing" && exit 1)

fetch-base:
	bash scripts/fetch_base_iso.sh

build:
	bash scripts/build_iso.sh

checksum:
	bash scripts/checksum.sh

verify:
	bash scripts/verify_iso.sh

clean:
	rm -rf build/work build/extract
