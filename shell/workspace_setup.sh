#!/usr/bin/env bash
set -euo pipefail

# Bootstrap the development environment.
#
# Initializes the shellshock submodule, syncs the shock dispatcher,
# and installs project tools declared in manifest.json.
#
# Usage: shell/workspace_setup.sh [args...]
#
# Arguments are forwarded to `shock workspace`.
# Examples:
#   shell/workspace_setup.sh              # install all tools
#   shell/workspace_setup.sh tokei gh     # install specific tools
#   shell/workspace_setup.sh --check      # check tool status
#   shell/workspace_setup.sh --force      # force reinstall

PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJ

function main() {
  init_submodule
  sync_dispatcher
  install_tools "$@"
}

function init_submodule() {
  if [[ ! -f "$PROJ/shell/.shock/shock" ]]; then
    echo "Initializing shellshock submodule..."
    git -C "$PROJ" submodule update --init shell/.shock
  fi
}

function sync_dispatcher() {
  cp "$PROJ/shell/.shock/shock" "$PROJ/shell/shock"
  chmod +x "$PROJ/shell/shock"
}

function install_tools() {
  TOOLS_SCRIPTS_DIR="$PROJ/shell/scripts" \
    "$PROJ/shell/shock" workspace "$@"
}

main "$@"
