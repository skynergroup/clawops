# ClawOps ISO — OS Hardening + OpenClaw Runtime Baseline

Implementation-ready baseline for an installer-built Linux appliance (Ubuntu/Debian family).

## Scope
- Host firewall baseline (UFW)
- SSH daemon hardening baseline
- Unattended security updates policy
- OpenClaw gateway as managed `systemd` service
- Runtime healthcheck + logrotate policy
- Acceptance tests to validate posture

## Assumptions
- Distribution: Ubuntu 22.04+/Debian 12+ (with `systemd`, `ufw`, `apt`)
- OpenClaw binary available at `/usr/local/bin/openclaw`
- Dedicated service account: `openclaw`
- Appliance management ingress via SSH (default TCP/22; overrideable)

## Quick apply order
Run as root:

```bash
cd /home/apollo/.openclaw/workspace/clawops
bash scripts/harden-firewall.sh
bash scripts/harden-ssh.sh
bash scripts/setup-unattended-upgrades.sh
bash scripts/install-gateway-systemd.sh
bash scripts/install-healthcheck.sh
bash tests/acceptance-hardening.sh
```

## Rollback guidance (minimal)
- Firewall: `ufw disable`
- SSH: restore `/etc/ssh/sshd_config.bak.*` then `systemctl reload ssh`
- Unattended upgrades: remove `/etc/apt/apt.conf.d/20auto-upgrades` and `52clawops-security`
- Gateway: `systemctl disable --now openclaw-gateway.service`
- Healthcheck timer: `systemctl disable --now openclaw-healthcheck.timer`

## Security defaults summary
- Default deny inbound, allow outbound
- SSH: password auth disabled, root login disabled, PAM yes, pubkey required
- Security-only unattended updates + auto-reboot at maintenance window
- `systemd` hardening directives on gateway service
- Healthcheck logs rotated daily with retention/compression
