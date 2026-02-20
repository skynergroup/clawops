#!/usr/bin/env bash
set -euo pipefail

SSH_PORT="${SSH_PORT:-22}"
SSH_GROUP="${SSH_GROUP:-sshusers}"
SSHD_CONFIG="/etc/ssh/sshd_config"
DROPIN_DIR="/etc/ssh/sshd_config.d"
DROPIN_FILE="${DROPIN_DIR}/60-clawops-hardening.conf"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "[ERROR] Run as root" >&2
    exit 1
  fi
}

backup_if_needed() {
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"
  cp -a "${SSHD_CONFIG}" "${SSHD_CONFIG}.bak.${ts}"
}

main() {
  require_root

  getent group "${SSH_GROUP}" >/dev/null || groupadd --system "${SSH_GROUP}"

  mkdir -p "${DROPIN_DIR}"
  backup_if_needed

  cat > "${DROPIN_FILE}" <<CFG
# Managed by ClawOps
Port ${SSH_PORT}
Protocol 2
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
UsePAM yes
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30
MaxAuthTries 3
MaxSessions 4
AllowGroups ${SSH_GROUP}
CFG

  sshd -t
  systemctl reload ssh || systemctl reload sshd
  echo "[INFO] SSH hardening applied via ${DROPIN_FILE}"
  echo "[INFO] Ensure admin users are in group: ${SSH_GROUP}"
}

main "$@"
