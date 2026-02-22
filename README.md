# ClawOps

> A bootable Linux server ISO with OpenClaw pre-installed and a first-boot setup wizard.

Built on Ubuntu Server 24.04 LTS. Install the OS → reboot → OpenClaw wizard runs automatically.

---

## What is ClawOps?

ClawOps is a purpose-built server OS image for running [OpenClaw](https://openclaw.ai) — your personal AI assistant. Instead of manually installing Node, OpenClaw, configuring systemd services, and wiring up channels, ClawOps handles all of it during OS installation and first boot.

**Install → Reboot → Done.**

---

## Features

- Ubuntu Server 24.04 LTS base (minimal, security-hardened)
- Node 22 + OpenClaw pre-installed
- Interactive first-boot wizard (`clawops-setup`) — configure AI provider, API key, messaging channel, Tailscale
- OpenClaw gateway runs as a systemd service (auto-starts, auto-restarts)
- SSH hardened by default (no root login, fail2ban, UFW firewall)
- Unattended security upgrades enabled
- Reproducible ISO build pipeline with SHA256 verification

---

## System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 1 core (x86_64) | 2+ cores |
| RAM | 1 GB | 2 GB |
| Disk | 10 GB | 20 GB |
| Network | Required | Required |

---

## Building the ISO

### Dependencies

```bash
sudo apt install -y xorriso 7zip squashfs-tools curl
```

Or use the Makefile:

```bash
make deps
```

### Build steps

```bash
make fetch-base   # Download + verify Ubuntu 24.04 base ISO
make build        # Remaster ISO with ClawOps overlay
make checksum     # Generate SHA256 for output ISO
```

Output: `out/clawops-1.0-amd64.iso`

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BASE_ISO` | `build/base.iso` | Path to Ubuntu base ISO |
| `OUTPUT_ISO` | `out/clawops-1.0-amd64.iso` | Output ISO path |
| `SKIP_DOWNLOAD` | `0` | Set to `1` to skip base ISO download |
| `CLAWOPS_VERSION` | `1.0` | Version tag for output filename |

---

## Installation

1. Flash `clawops-1.0-amd64.iso` to a USB drive:
   ```bash
   sudo dd if=out/clawops-1.0-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```
   Or use [Balena Etcher](https://etcher.balena.io/).

2. Boot the target machine from USB.

3. The Ubuntu autoinstall runs unattended — disk is formatted, packages installed, system configured.

4. Machine reboots automatically.

5. **First-boot wizard starts** on the console (TTY1). Follow the prompts to configure:
   - AI provider and API key
   - Messaging channel (Discord, Telegram, WhatsApp, or skip)
   - Tailscale (optional)

6. OpenClaw gateway starts. Access the WebUI at `http://<server-ip>:18789/`

---

## After Install

```bash
# Check gateway status
openclaw gateway status

# Re-run the setup wizard
clawops-setup

# View logs
journalctl -u openclaw-gateway -f

# Check system health
openclaw doctor
```

---

## Architecture

See [docs/architecture.md](docs/architecture.md) for the full build pipeline and first-boot flow.

---

## License

MIT — see [LICENSE](LICENSE).

Built on [OpenClaw](https://github.com/openclaw/openclaw) by the Skyner Group.
