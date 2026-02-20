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

GRUB_CFG="$EXTRACT/boot/grub/grub.cfg"
if [[ -f "$GRUB_CFG" ]]; then
  echo "[build] patching grub for autoinstall"
  sed -i 's#---# autoinstall ds=nocloud\\;s=/cdrom/autoinstall/ ---#g' "$GRUB_CFG"
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
xorriso -as mkisofs \
  -r -V 'CLAWOPS_UBUNTU_AUTO' \
  -o "$OUTPUT_ISO" \
  -J -l -iso-level 3 \
  -partition_offset 16 \
  -append_partition 2 0xef "$EXTRACT/efi.img" \
  -appended_part_as_gpt \
  -c '/boot.catalog' \
  -b '/boot/grub/i386-pc/eltorito.img' \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot \
  -e '--interval:appended_partition_2:all::' \
  -no-emul-boot \
  "$EXTRACT"

echo "[build] done: $OUTPUT_ISO"
