#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${KAITOSHOME:-}" ]]; then
  echo "fatal: KAITOSHOME must be set before running install.sh" >&2
  exit 1
fi

# shellcheck disable=SC1091
source "$KAITOSHOME/.envrc"

USAGE="$(cat <<EOF
Kaitos installer — runs inside an extracted release tarball.

Expects KAITOSHOME to be set to the tarball root (done by .envrc context
detection or the bootstrapper). Deploys the CLI, shared lib, Godot engine,
config template, and shell environment to XDG-compliant locations.

Usage:
  install.sh [--reset-configs]

Flags:
  -r, --reset-configs   Overwrite user config even if it already exists.
  -h, --help            Displays this help text

Post-install layout:
  ~/.local/
    bin/
      kaitos ...................... CLI binary
    share/
      kaitos/
        lib/
          libgodot.{so,dylib} ..... Shared Library for Godot integration
        shell/
          env.sh .................. Shell environment
  ~/.cache/
    kaitos/
      godot/
        <version>/ ................ Godot editor binary
  ~/.config/
    kaitos/
      settings.yaml ............... User config
EOF
)"

__install__XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
__install__XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
__install__CONFIG_DIR="$__install__XDG_CONFIG_HOME/kaitos"
__install__SHELL_ENV_DIR="$__install__XDG_DATA_HOME/kaitos/shell"
__install__FLAG_RESET_CONFIGS=false

function main() {
  parse_flags "$@"

  log_banner "Installing Kaitos"

  deploy_artifacts
  download_godot
  install_config
  install_shell_env
  patch_rc

  log ""
  log_banner "Installation complete!"
  log ""
  log "Restart your shell or run:"
  log "  source $__install__SHELL_ENV_DIR/env.sh"
}

function parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r|--reset-configs)
        __install__FLAG_RESET_CONFIGS=true
        shift
        ;;
      -h|--help)
        echo "$USAGE"
        exit 0
        ;;
      *)
        fatal "Unknown option: $1"
        echo "$USAGE"
        exit 1
        ;;
    esac
  done
}

: <<'DOC'
  Deploys CLI binary and shared library via deploy.api.sh.
  Source dir is the tarball root (KAITOSHOME).
DOC
function deploy_artifacts() {
  import "$KAITOSHOME/scripts/shared/deploy.api.sh"

  log "Deploying CLI and shared library..."

  # shellcheck disable=2034
  declare -A opts=( [source_dir]="$KAITOSHOME" )
  deploy_system opts
}

: <<'DOC'
  Downloads the Godot editor to XDG cache.
DOC
function download_godot() {
  import "$KAITOSHOME/scripts/shared/godot.api.sh"

  godot_download "$GODOT_VERSION"
}

: <<'DOC'
  Installs the settings template to XDG_CONFIG_HOME.

  Skips if the file already exists unless --reset-configs is passed.
  Expands __GODOT_VERSION__ placeholder with the actual version.
DOC
function install_config() {
  local target="$__install__CONFIG_DIR/settings.yaml"
  local template="$KAITOSHOME/templates/settings.template.yaml"

  if [[ -f "$target" && "$__install__FLAG_RESET_CONFIGS" == "false" ]]; then
    log "Config already exists at $target (use --reset-configs to overwrite)"
    return 0
  fi

  mkdir -p "$__install__CONFIG_DIR"
  sed "s|__GODOT_VERSION__|$GODOT_VERSION|g" "$template" > "$target"
  log "Installed config to $target"
}

: <<'DOC'
  Installs the shell environment file to XDG_DATA_HOME.

  Always overwrites — this file is kaitos-owned.
  Expands __KAITOS_VERSION__ and __GODOT_VERSION__ placeholders.
DOC
function install_shell_env() {
  local target="$__install__SHELL_ENV_DIR/env.sh"
  local template="$KAITOSHOME/templates/env.template.sh"
  local kaitos_version

  kaitos_version="$(__install__json_get "stable" "$KAITOSHOME/manifest.json")"

  mkdir -p "$__install__SHELL_ENV_DIR"
  sed \
    -e "s|__KAITOS_VERSION__|$kaitos_version|g" \
    -e "s|__GODOT_VERSION__|$GODOT_VERSION|g" \
    "$template" > "$target"
  log "Installed shell env to $target"
}

: <<'DOC'
  Extracts a top-level string value from a JSON file without jq.
  Only handles simple "key": "value" pairs — not nested paths.

  Usage: __install__json_get <key> <file>
DOC
function __install__json_get() {
  local key="$1" file="$2"
  local value

  value="$(grep "\"$key\"" "$file" | head -n 1 | sed 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"

  if [[ -z "$value" ]]; then
    fatal "Could not read '$key' from $file"
    return 1
  fi

  printf '%s' "$value"
}

: <<'DOC'
  Patches the user's shell rc file to source kaitos env.sh.

  Detects the default shell from $SHELL and targets the appropriate rc file.
  Idempotent: skips if the source line is already present.
DOC
function patch_rc() {
  local env_path="$__install__SHELL_ENV_DIR/env.sh"
  local source_line="# kaitos"$'\n'"[ -f \"$env_path\" ] && source \"$env_path\""
  local rc_file

  rc_file="$(__install__detect_rc_file)" || return 0

  if grep -qF "$env_path" "$rc_file" 2>/dev/null; then
    log "Shell rc already patched ($rc_file)"
    return 0
  fi

  printf '\n%s\n' "$source_line" >> "$rc_file"
  log "Patched $rc_file to source kaitos env"
}

function __install__detect_rc_file() {
  local shell_name
  shell_name="$(basename "${SHELL:-bash}")"

  case "$shell_name" in
    zsh)  echo "$HOME/.zshrc" ;;
    bash) echo "$HOME/.bashrc" ;;
    *)
      warn "Unsupported shell: $shell_name — please source $__install__SHELL_ENV_DIR/env.sh manually"
      return 1
      ;;
  esac
}

main "$@"
