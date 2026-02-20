# ClawOps — 5-Day ISO Delivery Plan

## Goal
Deliver in 5 days:
1. Bootable Ubuntu-based installer ISO artifact
2. Reproducible CI build (same inputs → same output hash)
3. Published checksums + verification step

---

## 1) Proposed repo structure (`skynergroup/clawops`)

```text
clawops/
  README.md
  Makefile
  docs/
    iso-build-plan.md
    decision-log.md
  iso/
    seed/
      user-data
      meta-data
    patches/
      grub.cfg.patch
  scripts/
    fetch_base_iso.sh
    build_iso.sh
    verify_iso.sh
    checksum.sh
  ci/
    container.Dockerfile
  .github/
    workflows/
      iso-build.yml
  build/               # intermediate build scratch
  out/                 # final ISO + checksum artifacts
  tests/
    smoke_boot.sh
```

---

## 2) Pipeline choice + rationale

## Chosen approach: Ubuntu live-server ISO remaster + embedded autoinstall (cloud-init NoCloud)

- Start from official Ubuntu live-server ISO (pinned URL + SHA256)
- Extract ISO filesystem
- Add `autoinstall` seed to `/autoinstall/user-data` and `/autoinstall/meta-data`
- Patch bootloader config to append:
  - `autoinstall`
  - `ds=nocloud\;s=/cdrom/autoinstall/`
- Repack hybrid bootable ISO using `xorriso`

### Why this approach
- Uses Canonical-supported autoinstall path
- Minimal mutation surface (safer than deep filesystem rebuild)
- Fast in CI
- Deterministic with pinned base ISO + controlled timestamps
- Easy to version-control seed config

### Not chosen (for now)
- Full custom image via `ubuntu-image`/live-build: more flexible but higher complexity/risk for 5-day deadline

---

## 3) Day-by-day execution

### Day 1 (done in this commit)
- Repo skeleton + scripts + Makefile
- Seed files (`user-data`, `meta-data`) baseline
- CI workflow skeleton
- Checksums/verify scripts

### Day 2
- Validate boot flow in VM (QEMU/KVM)
- Confirm unattended install starts automatically
- Add smoke test script

### Day 3
- Harden autoinstall profile (packages, users, SSH, storage template)
- Add decision log + parameterization for environments

### Day 4
- Reproducibility pass (stable timestamps/metadata, lock tool versions)
- CI reliability + retries + artifact retention

### Day 5
- Final test matrix (BIOS/UEFI)
- Release-ready docs + final checksums/signoff

---

## 4) Risks + mitigations

1. **Bootloader patch drift across Ubuntu versions**
   - Mitigation: patch guarded by grep checks; fail fast if expected tokens missing.

2. **Non-reproducible ISO metadata (timestamps/order)**
   - Mitigation: set fixed `SOURCE_DATE_EPOCH`; use deterministic xorriso options; pin builder container.

3. **Autoinstall schema regressions**
   - Mitigation: validate user-data in CI and run VM smoke install.

4. **Large artifact / CI timeout**
   - Mitigation: cache base ISO by SHA, separate fetch/build jobs, artifact compression + retention policy.

5. **Network dependency for package installs during setup**
   - Mitigation: keep Day-1 seed minimal; later define mirror strategy and offline fallback as needed.
