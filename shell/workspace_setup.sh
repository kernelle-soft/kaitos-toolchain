#!/usr/bin/env bash
set -euo pipefail

# Bootstrap the development environment.
#
# Initializes the shellshock submodule, copies the shock dispatcher,
# and installs project tools.
#
# Usage: shell/workspace_setup.sh [tools...]
#
# Arguments are forwarded to the tool installer. If none are given,
# all registered tools are installed.

PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
  "$PROJ/shell/scripts/chores/install_tools.sh" "$@"
}

main "$@"
