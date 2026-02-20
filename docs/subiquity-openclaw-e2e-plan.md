# ClawOps — Subiquity + OpenClaw E2E Execution Plan

## Objective
Produce a bootable Ubuntu Server ISO that performs standard machine setup and provisions OpenClaw during installation so OpenClaw is operational on first boot.

## Scope Lock (No Drift)
In scope:
- Ubuntu Server autoinstall (Subiquity/NoCloud)
- In-installer OpenClaw provisioning via `late-commands` + `curtin in-target`
- Systemd service enablement and first-boot validation
- Evidence artifacts and pass/fail report

Out of scope for this slice:
- Full UI setup and channel production credentials
- Multi-node orchestration UX
- Non-Ubuntu installers

## Stage Gates, Cutoffs, Success Criteria

### G0 — Requirements Lock
**Cutoff:** 30 minutes
**Tasks:**
- Freeze Ubuntu base version + checksum
- Freeze OpenClaw install method and config path
- Freeze minimum evidence set

**Success Criteria:**
- Decision log updated with immutable inputs
- No unresolved requirement questions

**Fail Action if cutoff missed:**
- Proceed with defaults in repo and flag assumptions explicitly

---

### G1 — Reproducible ISO Build
**Cutoff:** 90 minutes
**Tasks:**
- Build ISO from pinned Ubuntu source
- Inject autoinstall seed and patch bootloader args
- Generate and verify checksum

**Success Criteria:**
- `make build && make checksum && make verify` exits 0
- Artifact + `.sha256` present in `out/`
- Autoinstall kernel args present in ISO grub cfg

**Fail Action:**
- Ship last known-good ISO build scripts; block downstream stages

---

### G2 — Full Unattended Install Completes
**Cutoff:** 120 minutes
**Tasks:**
- Run VM unattended install from built ISO
- Capture serial logs
- Confirm target disk bootable

**Success Criteria:**
- Installer reaches completion without manual intervention
- VM reboots into installed OS
- Evidence log archived under `artifacts/install/`

**Fail Action:**
- Reduce autoinstall complexity (network/storage defaults), rerun once

---

### G3 — OpenClaw Provisioned During Install
**Cutoff:** 120 minutes
**Tasks:**
- Add installer hook script invoked by `late-commands`
- Install runtime dependencies + OpenClaw in target system
- Render `/etc/openclaw/openclaw.json` from template/env refs
- Install/enable `openclaw-gateway.service`

**Success Criteria:**
- On installed target: `which openclaw` exists
- `/etc/openclaw/openclaw.json` exists and permissions are restricted
- `systemctl is-enabled openclaw-gateway` returns enabled

**Fail Action:**
- Keep provisioning script but switch to first-boot one-shot service as fallback

---

### G4 — First-Boot Health Validation
**Cutoff:** 60 minutes
**Tasks:**
- Boot installed VM image
- Validate service status and CLI health
- Capture logs + diagnostics

**Success Criteria:**
- `systemctl is-active openclaw-gateway` = active
- `openclaw gateway status` exits 0
- Healthcheck log created and no fatal errors

**Fail Action:**
- Collect journal logs, patch service/env, rerun once

---

### G5 — Release Evidence Pack
**Cutoff:** 45 minutes
**Tasks:**
- Assemble pass/fail report
- Store checksums, commands, and logs
- Produce GO/NO-GO statement

**Success Criteria:**
- Single reproducible runbook from build to validation
- All mandatory checks marked pass or explicitly waived
- Clear next-step backlog for remaining scope

## Mandatory Command Checks
```bash
make fetch-base
make build
make checksum
make verify
bash tests/smoke_boot.sh out/clawops-ubuntu-autoinstall.iso

# On installed target VM
which openclaw
systemctl is-enabled openclaw-gateway
systemctl is-active openclaw-gateway
openclaw gateway status
journalctl -u openclaw-gateway --no-pager -n 200
```

## Execution Cadence
- 5-minute progress updates with:
  1) current gate,
  2) completion %, 
  3) blocker,
  4) next command.

## Immediate Next Actions (Now)
1. Implement G3 installer hook scripts in ISO seed.
2. Run full unattended install in QEMU with serial log capture.
3. Validate G4 health checks in installed system.
