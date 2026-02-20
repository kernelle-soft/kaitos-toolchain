#!/usr/bin/env bash
# Kaitos shell environment
# Installed to: ~/.local/share/kaitos/shell/env.sh
# Sourced from: ~/.bashrc or ~/.zshrc
#
# This file is owned by kaitos and overwritten on upgrade.
# Do not edit manually.

export KAITOS_VERSION="__KAITOS_VERSION__"
export GODOT_VERSION="__GODOT_VERSION__"

__KAITOS_BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
__KAITOS_GODOT="$HOME/.cache/kaitos/godot/$GODOT_VERSION"

if [[ ":$PATH:" != *":$__KAITOS_BIN:"* ]]; then
  export PATH="$__KAITOS_BIN:$PATH"
fi

if [[ ":$PATH:" != *":$__KAITOS_GODOT:"* ]]; then
  export PATH="$__KAITOS_GODOT:$PATH"
fi

unset __KAITOS_BIN __KAITOS_GODOT
