#!/usr/bin/env bash
# ClawOps environment setup (loaded on login)

# Add npm global bin to PATH if not already present
NPM_GLOBAL_BIN="$(npm root -g 2>/dev/null)/../bin" 2>/dev/null || true
if [[ -d "$NPM_GLOBAL_BIN" ]] && [[ ":$PATH:" != *":$NPM_GLOBAL_BIN:"* ]]; then
  export PATH="$NPM_GLOBAL_BIN:$PATH"
fi

# OpenClaw workspace
export OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"

# Alias
alias clawops-setup='/usr/local/bin/clawops-setup'

# Hint on first login if setup not done
if [[ ! -f "/var/lib/clawops/.setup-done" ]]; then
  echo ""
  echo "  ClawOps: Run the setup wizard to configure OpenClaw:"
  echo "    clawops-setup"
  echo ""
fi
