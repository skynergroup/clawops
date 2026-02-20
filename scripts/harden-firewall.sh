#!/usr/bin/env bash
set -euo pipefail

SSH_PORT="${SSH_PORT:-22}"
ALLOWED_TCP_PORTS="${ALLOWED_TCP_PORTS:-}"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "[ERROR] Run as root" >&2
    exit 1
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "[ERROR] Missing command: $1" >&2; exit 1; }
}

main() {
  require_root
  require_cmd ufw

  echo "[INFO] Configuring UFW baseline"
  ufw --force reset
  ufw default deny incoming
  ufw default allow outgoing

  ufw allow "${SSH_PORT}"/tcp comment 'clawops-ssh'

  if [[ -n "${ALLOWED_TCP_PORTS}" ]]; then
    IFS=',' read -r -a ports <<< "${ALLOWED_TCP_PORTS}"
    for p in "${ports[@]}"; do
      p_trimmed="$(echo "$p" | xargs)"
      [[ -n "$p_trimmed" ]] && ufw allow "$p_trimmed"/tcp comment 'clawops-extra'
    done
  fi

  ufw --force enable
  ufw status verbose
}

main "$@"
