# ClawOps Architecture

## Overview

ClawOps is a custom Ubuntu Server 24.04 LTS ISO with OpenClaw pre-installed and a first-boot configuration wizard.

```
┌─────────────────────────────────────────────────┐
│                  Build Pipeline                  │
│                                                  │
│  Ubuntu Server 24.04 ISO                        │
│         │                                        │
│         ▼                                        │
│  [extract with 7z]                               │
│         │                                        │
│         ▼                                        │
│  Inject autoinstall seed (user-data, meta-data)  │
│         │                                        │
│         ▼                                        │
│  Inject overlay into squashfs                    │
│  (firstboot wizard, systemd services, configs)   │
│         │                                        │
│         ▼                                        │
│  Patch GRUB (autoinstall boot args)              │
│         │                                        │
│         ▼                                        │
│  Repack ISO with xorriso (BIOS + UEFI hybrid)    │
│         │                                        │
│         ▼                                        │
│  clawops-1.0-amd64.iso                          │
└─────────────────────────────────────────────────┘
```

## Install Flow

```
User boots ClawOps ISO
        │
        ▼
GRUB: "ClawOps 1.0 (Ubuntu 24.04)"
        │
        ▼
Ubuntu Subiquity installer (autoinstall)
  - Disk layout (direct)
  - User: clawops
  - Packages: curl, git, ufw, fail2ban...
  - Late commands:
      • Install Node 22 (NodeSource)
      • npm install -g openclaw@latest
      • Copy overlay files
      • Enable clawops-firstboot.service
      • Configure UFW, fail2ban, SSH
        │
        ▼
System reboots automatically
        │
        ▼
First boot: clawops-firstboot.service fires
        │
        ▼
clawops-setup wizard runs on TTY1
  - Step 1: AI Provider (Anthropic/OpenAI/Gemini)
  - Step 2: API Key
  - Step 3: Messaging Channel (Discord/Telegram/skip)
  - Step 4: Tailscale (optional)
  - Writes: /home/clawops/.openclaw/config.json
  - Enables: openclaw-gateway.service
        │
        ▼
OpenClaw gateway starts (port 18789)
        │
        ▼
WebUI: http://<server-ip>:18789/
```

## Components

### autoinstall/user-data
Cloud-init autoinstall YAML. Drives unattended OS installation via Ubuntu's Subiquity installer. Late-commands install Node 22, OpenClaw, and inject overlay files.

### overlay/
Files copied into the installed system:

| Path | Purpose |
|------|---------|
| `usr/local/bin/clawops-setup.sh` | Interactive setup wizard |
| `etc/systemd/system/clawops-firstboot.service` | Triggers wizard on first boot |
| `etc/systemd/system/openclaw-gateway.service` | Runs OpenClaw gateway as a service |
| `etc/profile.d/clawops.sh` | PATH + env on login |
| `etc/motd.d/clawops` | SSH login banner |

### configs/
Host configuration files:

| Path | Purpose |
|------|---------|
| `configs/ssh/60-clawops-hardening.conf` | SSH security settings |
| `configs/apt/20auto-upgrades` | Unattended security updates |

### build.sh
Main ISO remastering script. Extracts the Ubuntu base ISO, injects the ClawOps overlay, patches GRUB, and repacks with xorriso.

## Security Defaults

| Setting | Value |
|---------|-------|
| Root login | Disabled |
| SSH password auth | Enabled (change to key-only post-install) |
| Firewall (UFW) | SSH (22) + Gateway (18789) only |
| Fail2ban | Enabled, default jails |
| Unattended upgrades | Enabled (security only) |
| Gateway bind | Loopback (127.0.0.1) |

## Networking

The OpenClaw gateway binds to `127.0.0.1:18789` by default. To expose it:
- **Tailscale (recommended):** set up during firstboot wizard, use Tailscale Serve for HTTPS
- **Reverse proxy:** nginx or caddy in front of port 18789
- **Direct bind:** change `gateway.bind` to `lan` in config (add auth token)
