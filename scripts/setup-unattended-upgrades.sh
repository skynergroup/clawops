#!/usr/bin/env bash
set -euo pipefail

AUTO_REBOOT="${AUTO_REBOOT:-true}"
REBOOT_TIME="${REBOOT_TIME:-03:30}"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "[ERROR] Run as root" >&2
    exit 1
  fi
}

main() {
  require_root
  export DEBIAN_FRONTEND=noninteractive

  apt-get update
  apt-get install -y unattended-upgrades apt-listchanges

  cat > /etc/apt/apt.conf.d/20auto-upgrades <<CFG
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
CFG

  cat > /etc/apt/apt.conf.d/52clawops-security <<CFG
Unattended-Upgrade::Allowed-Origins {
        "\${distro_id}:\${distro_codename}-security";
        "\${distro_id}ESMApps:\${distro_codename}-apps-security";
        "\${distro_id}ESM:\${distro_codename}-infra-security";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "${AUTO_REBOOT}";
Unattended-Upgrade::Automatic-Reboot-Time "${REBOOT_TIME}";
Unattended-Upgrade::Mail "";
Unattended-Upgrade::Verbose "false";
CFG

  systemctl enable --now unattended-upgrades.service
  unattended-upgrade --dry-run --debug || true
  echo "[INFO] Unattended security updates configured"
}

main "$@"
