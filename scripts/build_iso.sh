#!/usr/bin/env bash
set -euo pipefail

: "${BASE_ISO:=build/base.iso}"
: "${OUTPUT_ISO:=out/clawops-ubuntu-autoinstall.iso}"

WORKDIR=build/work
EXTRACT=build/extract
SEED_DIR=iso/seed

[[ -f "$BASE_ISO" ]] || { echo "Base ISO not found: $BASE_ISO"; exit 1; }
[[ -f "$SEED_DIR/user-data" ]] || { echo "Missing $SEED_DIR/user-data"; exit 1; }
[[ -f "$SEED_DIR/meta-data" ]] || { echo "Missing $SEED_DIR/meta-data"; exit 1; }

rm -rf "$WORKDIR" "$EXTRACT"
mkdir -p "$WORKDIR" "$EXTRACT" "$(dirname "$OUTPUT_ISO")"

echo "[build] extracting ISO"
7z x -y "$BASE_ISO" -o"$EXTRACT" >/dev/null

mkdir -p "$EXTRACT/autoinstall"
cp "$SEED_DIR/user-data" "$EXTRACT/autoinstall/user-data"
cp "$SEED_DIR/meta-data" "$EXTRACT/autoinstall/meta-data"
if [[ -f "$SEED_DIR/openclaw-provision.sh" ]]; then
  cp "$SEED_DIR/openclaw-provision.sh" "$EXTRACT/autoinstall/openclaw-provision.sh"
  chmod +x "$EXTRACT/autoinstall/openclaw-provision.sh"
fi

GRUB_CFG="$EXTRACT/boot/grub/grub.cfg"
AUTOINSTALL_ARGS=' autoinstall ds=nocloud\;s=/cdrom/autoinstall/ '
if [[ -f "$GRUB_CFG" ]]; then
  echo "[build] patching grub for autoinstall"
  if grep -q "autoinstall ds=nocloud" "$GRUB_CFG"; then
    echo "[build] grub already contains autoinstall args"
  else
    sed -i "s# ---#${AUTOINSTALL_ARGS}---#g" "$GRUB_CFG"
  fi
else
  echo "[warn] grub.cfg not found, skipping patch"
fi

if [[ -f "$EXTRACT/md5sum.txt" ]]; then
  echo "[build] refreshing md5sum.txt"
  (
    cd "$EXTRACT"
    find . -type f ! -name md5sum.txt -print0 | sort -z | xargs -0 md5sum > md5sum.txt
  )
fi

echo "[build] repacking ISO"
EFI_IMG=""
for p in "$EXTRACT/efi.img" "$EXTRACT/boot/grub/efi.img"; do
  if [[ -f "$p" ]]; then EFI_IMG="$p"; break; fi
done

if [[ -z "$EFI_IMG" ]]; then
  echo "[build] no efi.img found, building BIOS-only ISO"
  xorriso -as mkisofs \
    -r -V 'CLAWOPS_UBUNTU_AUTO' \
    -o "$OUTPUT_ISO" \
    -J -l -iso-level 3 \
    -c '/boot.catalog' \
    -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    "$EXTRACT"
else
  xorriso -as mkisofs \
    -r -V 'CLAWOPS_UBUNTU_AUTO' \
    -o "$OUTPUT_ISO" \
    -J -l -iso-level 3 \
    -partition_offset 16 \
    -append_partition 2 0xef "$EFI_IMG" \
    -appended_part_as_gpt \
    -c '/boot.catalog' \
    -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot \
    -e '--interval:appended_partition_2:all::' \
    -no-emul-boot \
    "$EXTRACT"
fi

echo "[build] done: $OUTPUT_ISO"
