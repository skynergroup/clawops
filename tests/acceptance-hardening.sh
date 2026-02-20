#!/usr/bin/env bash
set -euo pipefail

failures=0

pass() { echo "[PASS] $1"; }
fail() { echo "[FAIL] $1"; failures=$((failures+1)); }

check_cmd() {
  local desc="$1" cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi
}

check_text() {
  local desc="$1" cmd="$2" needle="$3"
  local out
  out="$(eval "$cmd" 2>/dev/null || true)"
  if grep -Fq "$needle" <<<"$out"; then pass "$desc"; else
    echo "      expected: $needle"
    echo "      got: ${out:0:200}"
    fail "$desc"
  fi
}

echo "== ClawOps hardening acceptance tests =="

check_cmd "UFW installed" "command -v ufw"
check_text "UFW default deny incoming" "ufw status verbose" "Default: deny (incoming)"
check_text "UFW SSH rule present" "ufw status numbered" "22/tcp"

check_cmd "SSH config syntax valid" "sshd -t"
check_text "SSH password auth disabled" "sshd -T" "passwordauthentication no"
check_text "SSH root login disabled" "sshd -T" "permitrootlogin no"

check_cmd "unattended-upgrades package installed" "dpkg -s unattended-upgrades"
check_text "Auto upgrades enabled" "cat /etc/apt/apt.conf.d/20auto-upgrades" "APT::Periodic::Unattended-Upgrade \"1\";"
check_text "Security origin configured" "cat /etc/apt/apt.conf.d/52clawops-security" "-security"

check_cmd "gateway service enabled" "systemctl is-enabled openclaw-gateway.service"
check_cmd "gateway service active" "systemctl is-active --quiet openclaw-gateway.service"
check_text "gateway has NoNewPrivileges" "systemctl cat openclaw-gateway.service" "NoNewPrivileges=true"

check_cmd "healthcheck timer enabled" "systemctl is-enabled openclaw-healthcheck.timer"
check_cmd "healthcheck timer active" "systemctl is-active --quiet openclaw-healthcheck.timer"
check_cmd "logrotate config valid" "logrotate -d /etc/logrotate.d/openclaw"

if [[ "$failures" -gt 0 ]]; then
  echo "== RESULT: FAIL ($failures checks failed) =="
  exit 1
fi

echo "== RESULT: PASS =="
