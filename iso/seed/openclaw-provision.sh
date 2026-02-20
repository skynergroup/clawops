#!/usr/bin/env bash
set -euxo pipefail

# Runs inside target system via curtin in-target.
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y curl ca-certificates gnupg lsb-release git jq

# Install Node.js 22.x
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y nodejs
fi

# Install OpenClaw CLI (prefer npm package, fallback to source install)
if ! command -v openclaw >/dev/null 2>&1; then
  npm install -g openclaw || {
    rm -rf /opt/openclaw-src
    git clone --depth 1 https://github.com/openclaw/openclaw.git /opt/openclaw-src
    npm install -g /opt/openclaw-src
  }
fi

# Minimal filesystem layout
install -d -m 0750 /etc/openclaw
install -d -m 0750 /var/lib/openclaw
install -d -m 0750 /var/log/openclaw

# Generate a first-boot baseline config only if absent.
if [ ! -f /etc/openclaw/openclaw.json ]; then
  cat >/etc/openclaw/openclaw.json <<'JSON'
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "enabled": true,
        "provider": "local",
        "fallback": "none"
      }
    }
  }
}
JSON
  chmod 0640 /etc/openclaw/openclaw.json
fi

# Create a dedicated runtime user if missing.
id -u openclaw >/dev/null 2>&1 || useradd --system --home /var/lib/openclaw --shell /usr/sbin/nologin openclaw
chown -R openclaw:openclaw /var/lib/openclaw /var/log/openclaw

# Install service unit
cat >/etc/systemd/system/openclaw-gateway.service <<'UNIT'
[Unit]
Description=OpenClaw Gateway
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=openclaw
Group=openclaw
WorkingDirectory=/var/lib/openclaw
ExecStart=/usr/local/bin/openclaw gateway start
ExecStop=/usr/local/bin/openclaw gateway stop
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable openclaw-gateway.service
# Best effort start during install context (may fail inside chroot); enabled state is mandatory.
systemctl start openclaw-gateway.service || true

# Post-install evidence
{
  echo "[openclaw-provision] completed at $(date -Is)"
  command -v openclaw || true
  node -v || true
  npm -v || true
  systemctl is-enabled openclaw-gateway.service || true
} >/var/log/openclaw/provision.log 2>&1
