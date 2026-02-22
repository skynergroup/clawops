#!/usr/bin/env bash
# clawops-setup — ClawOps first-boot interactive setup wizard
# Guides the user through configuring OpenClaw on first boot.
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

SETUP_DONE_FILE="/var/lib/clawops/.setup-done"
OPENCLAW_CONFIG_DIR="/var/lib/openclaw/.openclaw"

# ── Helpers ───────────────────────────────────────────────────────────────────
clear_screen() { clear 2>/dev/null || true; }
pause() { echo -e "${DIM}Press Enter to continue...${NC}"; read -r _; }

header() {
  clear_screen
  echo -e "${CYAN}"
  echo "  ╔═══════════════════════════════════════════════════╗"
  echo "  ║                                                   ║"
  echo "  ║   ██████╗██╗      █████╗ ██╗    ██╗ ██████╗  ██╗ ║"
  echo "  ║  ██╔════╝██║     ██╔══██╗██║    ██║██╔═══██╗██╔╝ ║"
  echo "  ║  ██║     ██║     ███████║██║ █╗ ██║██║   ██║███╗  ║"
  echo "  ║  ██║     ██║     ██╔══██║██║███╗██║██║   ██║╚██╗  ║"
  echo "  ║  ╚██████╗███████╗██║  ██║╚███╔███╔╝╚██████╔╝ ██╗  ║"
  echo "  ║   ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝  ╚═════╝  ╚═╝ ║"
  echo "  ║                                                   ║"
  echo "  ║           ClawOps — First Boot Setup             ║"
  echo "  ║           Powered by OpenClaw                    ║"
  echo "  ╚═══════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo ""
}

section() {
  echo ""
  echo -e "${YELLOW}  ── $* ──────────────────────────────────────${NC}"
  echo ""
}

prompt() {
  local label="$1"
  local var_name="$2"
  local default="${3:-}"
  local result

  if [[ -n "$default" ]]; then
    echo -ne "${CYAN}  ▸ ${BOLD}$label${NC} ${DIM}[${default}]${NC}: "
  else
    echo -ne "${CYAN}  ▸ ${BOLD}$label${NC}: "
  fi

  read -r result
  if [[ -z "$result" && -n "$default" ]]; then
    result="$default"
  fi
  printf -v "$var_name" '%s' "$result"
}

prompt_secret() {
  local label="$1"
  local var_name="$2"
  local result

  echo -ne "${CYAN}  ▸ ${BOLD}$label${NC} ${DIM}(hidden)${NC}: "
  read -rs result
  echo ""
  printf -v "$var_name" '%s' "$result"
}

success() { echo -e "  ${GREEN}✓${NC} $*"; }
error()   { echo -e "  ${RED}✗${NC} $*"; }
info()    { echo -e "  ${DIM}→${NC} $*"; }

# ── Step 1: AI Provider ───────────────────────────────────────────────────────
setup_provider() {
  section "Step 1 of 4 — AI Provider"

  echo "  Choose your AI provider:"
  echo ""
  echo "    1) Anthropic (Claude) — recommended"
  echo "    2) OpenAI (GPT)"
  echo "    3) Google Gemini"
  echo "    4) Other / I'll configure manually"
  echo ""

  local choice
  prompt "Choice" choice "1"

  case "$choice" in
    1)
      PROVIDER="anthropic"
      PROVIDER_NAME="Anthropic (Claude)"
      MODEL="anthropic/claude-sonnet-4-6"
      API_KEY_URL="https://console.anthropic.com/settings/keys"
      ;;
    2)
      PROVIDER="openai"
      PROVIDER_NAME="OpenAI (GPT)"
      MODEL="openai/gpt-4o"
      API_KEY_URL="https://platform.openai.com/api-keys"
      ;;
    3)
      PROVIDER="google"
      PROVIDER_NAME="Google Gemini"
      MODEL="google/gemini-2.0-flash"
      API_KEY_URL="https://aistudio.google.com/app/apikey"
      ;;
    4)
      PROVIDER="custom"
      PROVIDER_NAME="Custom"
      MODEL=""
      API_KEY_URL="your provider's dashboard"
      ;;
    *)
      PROVIDER="anthropic"
      PROVIDER_NAME="Anthropic (Claude)"
      MODEL="anthropic/claude-sonnet-4-6"
      API_KEY_URL="https://console.anthropic.com/settings/keys"
      ;;
  esac

  success "Provider: $PROVIDER_NAME"
}

# ── Step 2: API Key ───────────────────────────────────────────────────────────
setup_api_key() {
  section "Step 2 of 4 — API Key"
  echo "  Get your API key from:"
  echo "  ${DIM}$API_KEY_URL${NC}"
  echo ""

  local key=""
  while [[ -z "$key" ]]; do
    prompt_secret "API Key" key
    if [[ -z "$key" ]]; then
      error "API key cannot be empty."
    fi
  done

  API_KEY="$key"
  success "API key saved."
}

# ── Step 3: Messaging Channel ─────────────────────────────────────────────────
setup_channel() {
  section "Step 3 of 4 — Messaging Channel"

  echo "  Connect OpenClaw to a messaging platform:"
  echo ""
  echo "    1) Discord — bot responds in your server"
  echo "    2) Telegram — bot responds in Telegram"
  echo "    3) WhatsApp — requires WhatsApp Business API"
  echo "    4) Skip — configure manually later"
  echo ""

  local choice
  prompt "Choice" choice "4"

  CHANNEL_TYPE=""
  CHANNEL_TOKEN=""
  CHANNEL_EXTRA=""

  case "$choice" in
    1)
      CHANNEL_TYPE="discord"
      echo ""
      echo "  You'll need a Discord bot token."
      echo "  Create one at: ${DIM}https://discord.com/developers/applications${NC}"
      echo ""
      prompt_secret "Bot Token" CHANNEL_TOKEN
      prompt "Guild ID (server ID, right-click server → Copy ID)" CHANNEL_EXTRA ""
      success "Discord configured."
      ;;
    2)
      CHANNEL_TYPE="telegram"
      echo ""
      echo "  You'll need a Telegram bot token."
      echo "  Create one via: ${DIM}@BotFather on Telegram${NC}"
      echo ""
      prompt_secret "Bot Token" CHANNEL_TOKEN
      success "Telegram configured."
      ;;
    3)
      CHANNEL_TYPE="whatsapp"
      echo ""
      echo "  WhatsApp requires WhatsApp Business API."
      echo "  See: ${DIM}https://docs.openclaw.ai/channels/whatsapp${NC}"
      echo ""
      info "You can configure WhatsApp after setup by running: openclaw onboard"
      CHANNEL_TYPE=""
      ;;
    *)
      info "Skipping channel setup. Run 'openclaw onboard' to configure later."
      ;;
  esac
}

# ── Step 4: Tailscale ─────────────────────────────────────────────────────────
setup_tailscale() {
  section "Step 4 of 4 — Tailscale (Optional)"

  echo "  Tailscale provides secure remote access to your ClawOps instance."
  echo "  You can access the OpenClaw WebUI from anywhere via Tailscale."
  echo ""
  echo "  Get a Tailscale auth key at: ${DIM}https://login.tailscale.com/admin/settings/keys${NC}"
  echo ""

  local choice
  prompt "Enable Tailscale? (y/n)" choice "n"

  TAILSCALE_AUTH_KEY=""
  TAILSCALE_ENABLED=false

  if [[ "$choice" =~ ^[Yy]$ ]]; then
    if command -v tailscale &>/dev/null; then
      prompt_secret "Tailscale Auth Key" TAILSCALE_AUTH_KEY
      TAILSCALE_ENABLED=true
      success "Tailscale will be configured."
    else
      echo ""
      info "Installing Tailscale..."
      curl -fsSL https://tailscale.com/install.sh | sh 2>/dev/null || {
        error "Tailscale installation failed. You can install it later:"
        info "  curl -fsSL https://tailscale.com/install.sh | sh"
        return 0
      }
      prompt_secret "Tailscale Auth Key" TAILSCALE_AUTH_KEY
      TAILSCALE_ENABLED=true
      success "Tailscale installed and will be configured."
    fi
  else
    info "Skipping Tailscale. Run 'tailscale up' to configure later."
  fi
}

# ── Apply Configuration ───────────────────────────────────────────────────────
apply_config() {
  section "Applying Configuration"

  # Build openclaw config directory
  local config_dir="/home/clawops/.openclaw"
  mkdir -p "$config_dir"

  # Write gateway config
  local config_file="$config_dir/config.json"

  local provider_key_field
  case "$PROVIDER" in
    anthropic) provider_key_field='"anthropic": { "apiKey": "'"$API_KEY"'" }' ;;
    openai)    provider_key_field='"openai": { "apiKey": "'"$API_KEY"'" }' ;;
    google)    provider_key_field='"google": { "apiKey": "'"$API_KEY"'" }' ;;
    *)         provider_key_field='"custom": { "apiKey": "'"$API_KEY"'" }' ;;
  esac

  # Compose channel section
  local channel_section="{}"
  if [[ "$CHANNEL_TYPE" == "discord" && -n "$CHANNEL_TOKEN" ]]; then
    channel_section="{
      \"discord\": {
        \"token\": \"$CHANNEL_TOKEN\",
        \"groupPolicy\": \"open\"$(
          [[ -n "$CHANNEL_EXTRA" ]] && echo ",
        \"guildId\": \"$CHANNEL_EXTRA\""
        )
      }
    }"
  elif [[ "$CHANNEL_TYPE" == "telegram" && -n "$CHANNEL_TOKEN" ]]; then
    channel_section="{
      \"telegram\": {
        \"token\": \"$CHANNEL_TOKEN\"
      }
    }"
  fi

  cat > "$config_file" << CONFIG
{
  "model": "${MODEL:-anthropic/claude-sonnet-4-6}",
  "providers": {
    $provider_key_field
  },
  "channels": $channel_section,
  "gateway": {
    "port": 18789,
    "bind": "loopback"
  },
  "workspace": "/home/clawops/.openclaw/workspace"
}
CONFIG

  chown -R clawops:clawops "$config_dir"
  success "OpenClaw config written."

  # Enable and start gateway
  info "Enabling OpenClaw gateway service..."
  systemctl enable openclaw-gateway.service 2>/dev/null || true
  systemctl start openclaw-gateway.service 2>/dev/null && success "Gateway started." || {
    error "Gateway failed to start. Check: journalctl -u openclaw-gateway"
  }

  # Tailscale
  if [[ "$TAILSCALE_ENABLED" == "true" && -n "$TAILSCALE_AUTH_KEY" ]]; then
    info "Connecting to Tailscale..."
    tailscale up --authkey "$TAILSCALE_AUTH_KEY" --accept-routes 2>/dev/null && success "Tailscale connected." || {
      error "Tailscale connection failed. Run: tailscale up --authkey <key>"
    }
  fi
}

# ── Print summary ─────────────────────────────────────────────────────────────
print_summary() {
  local server_ip
  server_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "<server-ip>")

  clear_screen
  echo -e "${GREEN}"
  echo "  ╔═══════════════════════════════════════════════════╗"
  echo "  ║                                                   ║"
  echo "  ║         ClawOps Setup Complete!                  ║"
  echo "  ║                                                   ║"
  echo "  ╚═══════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo ""
  echo -e "  ${BOLD}OpenClaw WebUI:${NC}  http://$server_ip:18789/"
  echo -e "  ${BOLD}Gateway status:${NC}  openclaw gateway status"
  echo -e "  ${BOLD}Re-run wizard:${NC}   clawops-setup"
  echo -e "  ${BOLD}View logs:${NC}       journalctl -u openclaw-gateway -f"
  echo -e "  ${BOLD}Docs:${NC}            https://docs.openclaw.ai"
  echo ""

  if [[ "$TAILSCALE_ENABLED" == "true" ]]; then
    local ts_hostname
    ts_hostname=$(tailscale status --json 2>/dev/null | jq -r '.Self.DNSName // empty' | sed 's/\.$//') || true
    if [[ -n "$ts_hostname" ]]; then
      echo -e "  ${BOLD}Tailscale WebUI:${NC} https://$ts_hostname:18789/"
      echo ""
    fi
  fi

  echo -e "  ${DIM}Your OpenClaw assistant is running. Enjoy.${NC}"
  echo ""

  # Mark setup as done
  mkdir -p "$(dirname "$SETUP_DONE_FILE")"
  touch "$SETUP_DONE_FILE"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  # Check if already done
  if [[ -f "$SETUP_DONE_FILE" ]] && [[ "${FORCE_SETUP:-0}" != "1" ]]; then
    echo ""
    echo -e "${YELLOW}ClawOps has already been configured.${NC}"
    echo ""
    echo "  To re-run setup: FORCE_SETUP=1 clawops-setup"
    echo "  To reconfigure OpenClaw: openclaw onboard"
    echo "  Gateway status: openclaw gateway status"
    echo ""
    exit 0
  fi

  header

  echo "  Welcome to ClawOps — your OpenClaw-powered server."
  echo "  This wizard will configure your AI assistant in 4 steps."
  echo ""
  echo -e "  ${DIM}Press Ctrl+C at any time to exit. You can re-run this wizard with: clawops-setup${NC}"
  echo ""
  pause

  # Declare global vars
  PROVIDER=""
  PROVIDER_NAME=""
  MODEL=""
  API_KEY_URL=""
  API_KEY=""
  CHANNEL_TYPE=""
  CHANNEL_TOKEN=""
  CHANNEL_EXTRA=""
  TAILSCALE_ENABLED=false
  TAILSCALE_AUTH_KEY=""

  setup_provider
  setup_api_key
  setup_channel
  setup_tailscale
  apply_config
  print_summary
}

main "$@"
