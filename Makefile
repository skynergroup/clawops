.PHONY: all deps fetch-base build checksum verify clean help

CLAWOPS_VERSION ?= 1.0
BASE_ISO        ?= build/base.iso
OUTPUT_ISO      ?= out/clawops-$(CLAWOPS_VERSION)-amd64.iso

all: build

## Install build dependencies
deps:
	@echo "[deps] Installing build dependencies..."
	sudo apt-get update -qq
	sudo apt-get install -y xorriso 7zip squashfs-tools curl wget
	@echo "[deps] Done."

## Download and verify the Ubuntu 24.04 base ISO
fetch-base:
	@bash scripts/fetch_base_iso.sh

## Remaster ISO with ClawOps overlay
build:
	@BASE_ISO=$(BASE_ISO) OUTPUT_ISO=$(OUTPUT_ISO) bash build.sh

## Generate SHA256 checksum for output ISO
checksum:
	@bash scripts/checksum.sh $(OUTPUT_ISO)

## Verify the output ISO checksum
verify:
	@bash scripts/verify_iso.sh $(OUTPUT_ISO)

## Remove build artifacts (keep base ISO)
clean:
	@echo "[clean] Removing build artifacts..."
	rm -rf build/work build/extract out/
	@echo "[clean] Done."

## Remove everything including base ISO
distclean: clean
	@echo "[distclean] Removing base ISO..."
	rm -rf build/
	@echo "[distclean] Done."

## Show this help
help:
	@echo ""
	@echo "ClawOps ISO Builder"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@grep -E '^##' Makefile | sed 's/## /  /'
	@echo ""
	@echo "Environment variables:"
	@echo "  CLAWOPS_VERSION  (default: 1.0)"
	@echo "  BASE_ISO         (default: build/base.iso)"
	@echo "  OUTPUT_ISO       (default: out/clawops-VERSION-amd64.iso)"
	@echo "  SKIP_DOWNLOAD    Set to 1 to skip ISO download"
	@echo ""
