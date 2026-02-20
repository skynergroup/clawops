# Decision Log

## 2026-02-20 — ISO build strategy
- Decision: Remaster official Ubuntu live-server ISO and embed NoCloud autoinstall seed.
- Rationale: Lowest complexity path to a reliable installer artifact within 5-day window.
- Tradeoff: Less flexible than full custom rootfs build, but much faster and safer.
