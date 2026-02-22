#!/usr/bin/env bash
# build.sh — ClawOps ISO remastering pipeline
# Produces a bootable Ubuntu Server 24.04 ISO with OpenClaw pre-installed
# and a first-boot setup wizard.
set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
: "${BASE_ISO:=build/base.iso}"
: "${OUTPUT_ISO:=out/clawops-1.0-amd64.iso}"
: "${CLAWOPS_VERSION:=1.0}"
: "${SKIP_SQUASHFS:=0}"

WORKDIR=build/work
EXTRACT=build/extract
CHROOT=build/chroot
AUTOINSTALL_DIR=autoinstall
OVERLAY_DIR=overlay

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
step()  { echo -e "${CYAN}[build]${NC} $*"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $*"; }
die()   { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

# ── Dependency check ─────────────────────────────────────────────────────────
check_deps() {
  local missing=()
  for cmd in xorriso 7z mksquashfs unsquashfs curl; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    die "Missing required tools: ${missing[*]}. Run: make deps"
  fi
  ok "All dependencies present."
}

# ── Verify base ISO exists ────────────────────────────────────────────────────
check_base_iso() {
  [[ -f "$BASE_ISO" ]] || die "Base ISO not found: $BASE_ISO — run: make fetch-base"
  step "Base ISO: $BASE_ISO ($(du -sh "$BASE_ISO" | cut -f1))"
}

# ── Extract ISO ───────────────────────────────────────────────────────────────
extract_iso() {
  step "Extracting ISO to $EXTRACT..."
  rm -rf "$EXTRACT" "$WORKDIR"
  mkdir -p "$EXTRACT" "$WORKDIR" "$(dirname "$OUTPUT_ISO")"
  7z x -y "$BASE_ISO" -o"$EXTRACT" >/dev/null
  ok "ISO extracted."
}

# ── Inject autoinstall seed ───────────────────────────────────────────────────
inject_autoinstall() {
  step "Injecting autoinstall seed..."
  [[ -f "$AUTOINSTALL_DIR/user-data" ]] || die "Missing: $AUTOINSTALL_DIR/user-data"
  [[ -f "$AUTOINSTALL_DIR/meta-data" ]] || die "Missing: $AUTOINSTALL_DIR/meta-data"

  mkdir -p "$EXTRACT/autoinstall"
  cp "$AUTOINSTALL_DIR/user-data" "$EXTRACT/autoinstall/user-data"
  cp "$AUTOINSTALL_DIR/meta-data" "$EXTRACT/autoinstall/meta-data"
  ok "Autoinstall seed injected."
}

# ── Copy overlay + configs to ISO root (accessible at /cdrom/ during install) ─
inject_iso_root() {
  step "Copying overlay/ and configs/ to ISO root..."

  if [[ -d "$OVERLAY_DIR" ]]; then
    cp -r "$OVERLAY_DIR" "$EXTRACT/overlay"
    ok "overlay/ → $EXTRACT/overlay/"
  else
    warn "No overlay/ directory found — skipping."
  fi

  if [[ -d "configs" ]]; then
    cp -r "configs" "$EXTRACT/configs"
    ok "configs/ → $EXTRACT/configs/"
  else
    warn "No configs/ directory found — skipping."
  fi
}

# ── Inject overlay files into squashfs ───────────────────────────────────────
inject_overlay() {
  step "Injecting overlay files into squashfs..."

  # Find the squashfs filesystem
  local squashfs=""
  for p in \
    "$EXTRACT/casper/filesystem.squashfs" \
    "$EXTRACT/live/filesystem.squashfs" \
    "$EXTRACT/install/filesystem.squashfs"
  do
    [[ -f "$p" ]] && { squashfs="$p"; break; }
  done

  if [[ -z "$squashfs" ]]; then
    warn "No squashfs found — overlay files will be injected via autoinstall late-commands only."
    return 0
  fi

  local squashfs_dir
  squashfs_dir="$(dirname "$squashfs")"

  # Unsquash
  local unsquash_dir="$WORKDIR/squashfs-root"
  rm -rf "$unsquash_dir"
  step "  Unsquashing $squashfs..."
  unsquashfs -d "$unsquash_dir" "$squashfs" >/dev/null
  ok "  Unsquashed."

  # Copy overlay tree
  if [[ -d "$OVERLAY_DIR" ]]; then
    cp -r "$OVERLAY_DIR/." "$unsquash_dir/"
    ok "  Overlay files copied."
  else
    warn "  No overlay/ directory found — skipping."
  fi

  # Repack squashfs
  step "  Repacking squashfs (this takes a while)..."
  rm -f "$squashfs"
  mksquashfs "$unsquash_dir" "$squashfs" -comp xz -noappend -no-progress 2>/dev/null
  ok "  Squashfs repacked."

  # Update manifest if present
  local manifest="$squashfs_dir/filesystem.manifest"
  if [[ -f "$manifest" ]]; then
    chroot "$unsquash_dir" dpkg-query -W --showformat='${Package} ${Version}\n' > "$manifest" 2>/dev/null || true
  fi

  rm -rf "$unsquash_dir"
}

# ── Patch GRUB for autoinstall ────────────────────────────────────────────────
patch_grub() {
  step "Patching GRUB for autoinstall..."
  local grub_cfg="$EXTRACT/boot/grub/grub.cfg"

  if [[ ! -f "$grub_cfg" ]]; then
    warn "grub.cfg not found at $grub_cfg — trying alternate locations."
    grub_cfg=$(find "$EXTRACT" -name grub.cfg 2>/dev/null | head -1)
    [[ -n "$grub_cfg" ]] || { warn "No grub.cfg found — skipping GRUB patch."; return 0; }
  fi

  local autoinstall_args='autoinstall ds=nocloud\;s=/cdrom/autoinstall/ '

  if grep -q "ds=nocloud" "$grub_cfg"; then
    ok "GRUB already contains autoinstall args."
  else
    # Patch all linux/linuxefi boot entries
    sed -i "s| ---| ${autoinstall_args}---|g" "$grub_cfg"
    ok "GRUB patched."
  fi

  # Update ClawOps menu title
  sed -i "s/Ubuntu Server/ClawOps ${CLAWOPS_VERSION} (Ubuntu 24.04)/g" "$grub_cfg" 2>/dev/null || true
}

# ── Refresh md5sum.txt ────────────────────────────────────────────────────────
refresh_checksums() {
  step "Refreshing md5sum.txt..."
  if [[ -f "$EXTRACT/md5sum.txt" ]]; then
    (
      cd "$EXTRACT"
      find . -type f ! -name md5sum.txt -print0 \
        | sort -z \
        | xargs -0 md5sum > md5sum.txt
    )
    ok "md5sum.txt updated."
  else
    warn "No md5sum.txt in extract dir — skipping."
  fi
}

# ── Repack ISO ────────────────────────────────────────────────────────────────
repack_iso() {
  step "Repacking ISO → $OUTPUT_ISO..."

  # Find EFI image for hybrid BIOS+UEFI
  local efi_img=""
  for p in \
    "$EXTRACT/efi.img" \
    "$EXTRACT/boot/grub/efi.img" \
    "$EXTRACT/.disk/info"
  do
    [[ -f "$p" ]] && [[ "$p" == *.img ]] && { efi_img="$p"; break; }
  done

  local vol_label="CLAWOPS_${CLAWOPS_VERSION//./}"

  if [[ -n "$efi_img" ]]; then
    step "  Building BIOS+UEFI hybrid ISO..."
    xorriso -as mkisofs \
      -r -V "$vol_label" \
      -o "$OUTPUT_ISO" \
      -J -l -iso-level 3 \
      -partition_offset 16 \
      -append_partition 2 0xef "$efi_img" \
      -appended_part_as_gpt \
      -c '/boot.catalog' \
      -b '/boot/grub/i386-pc/eltorito.img' \
      -no-emul-boot -boot-load-size 4 -boot-info-table \
      -eltorito-alt-boot \
      -e '--interval:appended_partition_2:all::' \
      -no-emul-boot \
      "$EXTRACT" 2>/dev/null
  else
    step "  Building BIOS-only ISO (no efi.img found)..."
    xorriso -as mkisofs \
      -r -V "$vol_label" \
      -o "$OUTPUT_ISO" \
      -J -l -iso-level 3 \
      -c '/boot.catalog' \
      -b '/boot/grub/i386-pc/eltorito.img' \
      -no-emul-boot -boot-load-size 4 -boot-info-table \
      "$EXTRACT" 2>/dev/null
  fi

  ok "ISO written: $OUTPUT_ISO ($(du -sh "$OUTPUT_ISO" | cut -f1))"
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║       ClawOps ISO build complete!        ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
  echo ""
  echo "  Output: $OUTPUT_ISO"
  echo "  Size:   $(du -sh "$OUTPUT_ISO" | cut -f1)"
  echo ""
  echo "  Flash to USB:"
  echo "    sudo dd if=$OUTPUT_ISO of=/dev/sdX bs=4M status=progress oflag=sync"
  echo ""
  echo "  Generate checksum:"
  echo "    make checksum"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║     ClawOps ISO Builder v${CLAWOPS_VERSION}            ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
  echo ""

  check_deps
  check_base_iso
  extract_iso
  inject_autoinstall
  inject_iso_root
  [[ "$SKIP_SQUASHFS" != "1" ]] && inject_overlay
  patch_grub
  refresh_checksums
  repack_iso
  print_summary
}

main "$@"
