#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_BIN="${OPENCLAW_BIN:-/usr/local/bin/openclaw}"
SERVICE_USER="${SERVICE_USER:-openclaw}"
SERVICE_GROUP="${SERVICE_GROUP:-openclaw}"
WORK_DIR="${WORK_DIR:-/var/lib/openclaw}"
ENV_FILE="/etc/default/openclaw-gateway"
UNIT_FILE="/etc/systemd/system/openclaw-gateway.service"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "[ERROR] Run as root" >&2
    exit 1
  fi
}

main() {
  require_root

  id -u "${SERVICE_USER}" >/dev/null 2>&1 || useradd --system --home "${WORK_DIR}" --create-home --shell /usr/sbin/nologin "${SERVICE_USER}"
  getent group "${SERVICE_GROUP}" >/dev/null || groupadd --system "${SERVICE_GROUP}"
  usermod -g "${SERVICE_GROUP}" "${SERVICE_USER}" || true

  install -d -o "${SERVICE_USER}" -g "${SERVICE_GROUP}" -m 0750 "${WORK_DIR}"
  install -d -o root -g root -m 0755 /var/log/openclaw

  cat > "${ENV_FILE}" <<CFG
# Managed by ClawOps
OPENCLAW_LOG_LEVEL=info
OPENCLAW_GATEWAY_ARGS=
CFG
  chmod 0640 "${ENV_FILE}"

  cat > "${UNIT_FILE}" <<CFG
[Unit]
Description=OpenClaw Gateway
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
WorkingDirectory=${WORK_DIR}
EnvironmentFile=${ENV_FILE}
ExecStart=${OPENCLAW_BIN} gateway start \$OPENCLAW_GATEWAY_ARGS
ExecStop=${OPENCLAW_BIN} gateway stop
Restart=on-failure
RestartSec=5s
TimeoutStartSec=60
TimeoutStopSec=30
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=${WORK_DIR} /var/log/openclaw
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictRealtime=true
RestrictSUIDSGID=true
SystemCallArchitectures=native

[Install]
WantedBy=multi-user.target
CFG

  systemctl daemon-reload
  systemctl enable --now openclaw-gateway.service
  systemctl status --no-pager openclaw-gateway.service || true
  echo "[INFO] OpenClaw gateway systemd service installed"
}

main "$@"
