# ClawOps Install Guide

## Prerequisites

- A physical machine or VM with:
  - x86_64 CPU
  - 1 GB RAM minimum (2 GB recommended)
  - 10 GB disk minimum
  - Network connection
- A USB drive (8 GB+) or VM ISO attachment
- An AI provider API key (Anthropic, OpenAI, or Gemini)

---

## Step 1: Get the ISO

**Option A — Download pre-built (recommended)**

Download the latest `clawops-X.X-amd64.iso` from [GitHub Releases](https://github.com/skynergroup/clawops/releases).

**Option B — Build from source**

```bash
git clone https://github.com/skynergroup/clawops.git
cd clawops
make deps
make fetch-base
make build
```

Output: `out/clawops-1.0-amd64.iso`

---

## Step 2: Flash to USB

### Linux/macOS

```bash
sudo dd if=clawops-1.0-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Replace `/dev/sdX` with your USB device (check with `lsblk`).

### Windows

Use [Balena Etcher](https://etcher.balena.io/) — select the ISO and your USB drive.

---

## Step 3: Boot and Install

1. Insert the USB drive into your target machine.
2. Boot from USB (hold F12/F2/Del at startup to select boot device).
3. GRUB shows **"ClawOps 1.0 (Ubuntu 24.04)"** — press Enter or wait.
4. The installer runs **automatically** (unattended autoinstall):
   - Disk is formatted and partitioned
   - Ubuntu is installed
   - Node 22 + OpenClaw are installed
   - System is configured (SSH, UFW, fail2ban)
5. Machine reboots automatically. **Remove the USB drive when prompted or at reboot.**

> The install takes approximately 5-15 minutes depending on hardware and internet speed.

---

## Step 4: First-Boot Setup Wizard

After reboot, the **ClawOps Setup Wizard** runs automatically on the console (TTY1).

If you're accessing via SSH, the wizard won't appear — check the console directly, or run it manually after logging in:

```bash
ssh clawops@<server-ip>
clawops-setup
```

### Wizard steps:

**Step 1 — AI Provider**
Choose: Anthropic (Claude), OpenAI, Gemini, or other.

**Step 2 — API Key**
Enter your API key (input is hidden). Get one from:
- Anthropic: https://console.anthropic.com/settings/keys
- OpenAI: https://platform.openai.com/api-keys
- Gemini: https://aistudio.google.com/app/apikey

**Step 3 — Messaging Channel**
Connect Discord, Telegram, or skip for now.

**Step 4 — Tailscale (optional)**
For secure remote access. Enter a Tailscale auth key or skip.

---

## Step 5: Verify

After the wizard completes:

```bash
# Check gateway is running
openclaw gateway status

# Open WebUI
openclaw dashboard
# Or: http://<server-ip>:18789/
```

---

## Default Credentials

| Setting | Value |
|---------|-------|
| Username | `clawops` |
| Password | Set during autoinstall (see `autoinstall/user-data`) |
| SSH port | 22 |
| Gateway port | 18789 (loopback only) |

---

## Post-Install Recommendations

1. **Change SSH password** or switch to key-based auth:
   ```bash
   ssh-copy-id clawops@<server-ip>
   ```

2. **Set Discord channel allowlist** if using Discord (currently open):
   ```bash
   openclaw config set channels.discord.groupPolicy restricted
   ```

3. **Enable Tailscale Serve** for HTTPS access:
   ```bash
   tailscale serve https:443 / http://localhost:18789
   ```

4. **Update OpenClaw** to latest:
   ```bash
   npm update -g openclaw
   openclaw gateway restart
   ```

---

## Troubleshooting

**Wizard didn't run on first boot**
```bash
clawops-setup         # Run manually
# Or force re-run:
FORCE_SETUP=1 clawops-setup
```

**Gateway not starting**
```bash
journalctl -u openclaw-gateway -f
openclaw doctor
```

**Can't access WebUI**
```bash
# Check if gateway is running
openclaw gateway status

# Check port
ss -tlnp | grep 18789

# Check firewall
sudo ufw status
```

**Re-run setup from scratch**
```bash
rm /var/lib/clawops/.setup-done
clawops-setup
```
