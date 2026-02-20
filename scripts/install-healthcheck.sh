#!/usr/bin/env bash
set -euo pipefail

HC_SCRIPT="/usr/local/libexec/openclaw-healthcheck.sh"
HC_SERVICE="/etc/systemd/system/openclaw-healthcheck.service"
HC_TIMER="/etc/systemd/system/openclaw-healthcheck.timer"
LOGROTATE_FILE="/etc/logrotate.d/openclaw"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "[ERROR] Run as root" >&2
    exit 1
  fi
}

main() {
  require_root

  install -d -m 0755 /usr/local/libexec
  install -d -m 0755 /var/log/openclaw

  cat > "${HC_SCRIPT}" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
LOG_FILE="/var/log/openclaw/healthcheck.log"
TS="$(date --iso-8601=seconds)"

status="ok"
msg="gateway healthy"

if ! systemctl is-active --quiet openclaw-gateway.service; then
  status="fail"
  msg="gateway inactive"
fi

if ! openclaw gateway status >/dev/null 2>&1; then
  status="fail"
  msg="gateway cli status failed"
fi

echo "${TS} status=${status} msg=\"${msg}\"" >> "${LOG_FILE}"

if [[ "${status}" == "fail" ]]; then
  systemctl restart openclaw-gateway.service || true
  exit 1
fi
SCRIPT
  chmod 0755 "${HC_SCRIPT}"

  cat > "${HC_SERVICE}" <<CFG
[Unit]
Description=OpenClaw Gateway Healthcheck
After=openclaw-gateway.service

[Service]
Type=oneshot
ExecStart=${HC_SCRIPT}
CFG

  cat > "${HC_TIMER}" <<CFG
[Unit]
Description=Run OpenClaw healthcheck every 2 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=2min
AccuracySec=15s
Unit=openclaw-healthcheck.service
Persistent=true

[Install]
WantedBy=timers.target
CFG

  cat > "${LOGROTATE_FILE}" <<CFG
/var/log/openclaw/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        /bin/systemctl kill -s HUP openclaw-gateway.service >/dev/null 2>&1 || true
    endscript
}
CFG

  systemctl daemon-reload
  systemctl enable --now openclaw-healthcheck.timer
  systemctl start openclaw-healthcheck.service || true
  logrotate -d "${LOGROTATE_FILE}" || true

  echo "[INFO] Healthcheck + logrotate installed"
}

main "$@"
