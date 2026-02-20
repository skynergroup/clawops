# ClawOps ISO Builder (Ubuntu)

Reproducible pipeline to build a bootable Ubuntu installer ISO with embedded `autoinstall` (cloud-init NoCloud).

## Quick start (Day 1)

```bash
cd clawops
make deps
make fetch-base
make build
make checksum
make verify
```

Artifacts are written to `out/`.

## Build model

- Base: Ubuntu live-server ISO (pinned URL + SHA256)
- Remaster: inject `autoinstall` seed into ISO (`/autoinstall/{user-data,meta-data}`)
- Boot args: force unattended install via kernel cmdline
- Reproducibility: pinned base checksum + deterministic output metadata + CI checksums

See `docs/iso-build-plan.md`.
