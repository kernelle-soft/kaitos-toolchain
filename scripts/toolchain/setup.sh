#!/usr/bin/env bash
set -eo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Installer for the ${TOOLCHAIN_NAME} game development framework.

Usage: "setup.sh [-c,--clean] [-h,--help]"

Flags:
  -c, --clean      Force a clean re-install
  -h, --help      Show this help text.
EOF
)"

source "$REPO_ROOT/scripts/shared/log.sh"

FLAG_CLEAN=false

TOOLCHAIN_NAME="${TOOLCHAIN_NAME?:tool}"
PATH_CONFIG="$HOME/.config/$TOOLCHAIN_NAME"
PATH_SHARE="$HOME/.local/share/$TOOLCHAIN_NAME"
PATH_BIN="$HOME/.local/bin"
PATH_COMMAND="$PATH_BIN/$TOOLCHAIN_NAME"
PATH_CACHE="$HOME/.cache/$TOOLCHAIN_NAME"

function main() {
  local engine

  parse_flags "$@"
  if ! is_user_ready; then
    log "Exiting"
    exit 0
  fi

  remove_install
  create_empty_install

  download_toolchain

  install_settings

  engine="$(download_engine)"
  bind_engine "$engine"
}

: <<'DOC'
  Parses CLI flags. 
  See USAGE for flag descriptions.
DOC
function parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--clean)
        FLAG_CLEAN=true
        shift
        ;;
      -h|--help)
        echo "$USAGE"
        exit 0
        ;;
      *)
        log "Unknown option: $1"
        log "$USAGE"
        exit 1
        ;;
    esac
  done
}

: <<'DOC'
  Double checks the current state of any pre-existing installations.
  
  Returns 1 if there's a pre-existing install AND 
  the user doesn't want to do a clean re-install. 
  
  Returns 0 otherwise, or if -c,--clean is passed.
DOC
function is_user_ready() {
  # Skip checks if --clean
  [[ -n "$FLAG_CLEAN" ]] && return 0;

  if has_complete_install; then
    log "There's already an installation of $TOOLCHAIN_NAME."
    read "Would you like to do a clean re-install (N/y)? " answer

    if [[ -z "$answer" || "$answer" == [Nn] ]]; then
      return 1
    fi
  fi

  if has_partial_install; then
    log "It looks like there's a corrupted installation of $TOOLCHAIN_NAME."
    read "Would you like to do a clean re-install (Y/n)? " answer

    if [[ -n "$answer" ]]; then
      if [[ "$answer" == [Nn] ]]; then
        return 1
      fi
    fi
  fi

  return 0
}

: <<'DOC'
  Checks if the user has all necessary components of the toolchain installed.

  Returns 0 if yes, 1 if no.
DOC
function has_complete_install() {
  if [[ 
    -d "$PATH_CONFIG" &&
    -d "$PATH_SHARE" &&
    -f "$PATH_COMMAND"
  ]]; then
    return 0
  fi

  return 1
}

: <<'DOC'
  Checks if the user is missing pieces of the toolchain.

  Returns 0 if yes, 1 if no.
DOC
function has_partial_install() {
  if [[ -z $(has_complete_install) ]]; then
    if [[
      -d "$PATH_CONFIG" ||
      -d "$PATH_SHARE" ||
      -f "$PATH_COMMAND"
    ]]; then
      return 0
    fi
  fi

  return 1
}

: <<'DOC'
  Removes the global components of the toolchain, including the cache cached versions.
DOC
function remove_install() {
  rm -rf "$PATH_CONFIG"
  rm -rf "$PATH_SHARE"
  rm -rf "$PATH_COMMAND"
  rm -rf "$PATH_CACHE"
}

: <<'DOC'
  Creates a fresh directory structure for installing the toolchain.
DOC
function create_empty_install() {
  mkdir -p "$PATH_CONFIG"
  mkdir -p "$PATH_SHARE"
  mkdir -p "$PATH_BIN"
  mkdir -p "$PATH_CACHE"
}

: <<'DOC'
  Downloads and extracts the toolchain into the user's HOME.
DOC
function download_toolchain() {
  # TODO
  # curl and download latest release to $HOME/.cache/{TOOLCHAIN_NAME}/{TOOLCHAIN_VERSION}/bundle.zip
  # extract $HOME/.cache/{TOOLCHAIN_NAME}/{TOOLCHAIN_VERSION}/bundle.zip to
  # $HOME/.local/share/{TOOLCHAIN_NAME}/{TOOLCHAIN_VERSION}/ and $HOME/.local/bin/{TOOLCHAIN_NAME}
  # - bin: the thin wrapper that coordinates godot and the transpiler
  # - share: the rest of the guts
  log "Downloading latest bundle"
}

: <<'DOC'
  Copies over the settings template into the global config directory, dynamically expanding any existing variables.
DOC
function install_settings() {
  sed -e "s/__TOOLCHAIN_VERSION__/$TOOLCHAIN_VERSION/" \
    "scripts/toolchain/template_settings.yaml" > "$HOME/.config/$TOOLCHAIN_NAME/settings.yaml"
}

function download_engine() {
  local engine_choice

  engine_choice="$(get_user_engine_choice)"

  # TODO
  # Download the appropriate engine at the appropriate version
  # Download it to the cache at TOOLCHAIN_VERSION
  # Install it to .local/share/{TOOLCHAIN_NAME}/{TOOL_CHAIN_VERSION}/{ENGINE_NAME}
  log "Downloading $engine_choice"
  ret "$engine_choice"
}

: <<'DOC'
  Gets the user's choice regarding the game engine they'd like to use for a runtime backend and editor.

  Default: godot
DOC
function get_user_engine_choice() {
  local options=("godot" "bevy")
  local default="godot"
  {
    PS3="Select engine: "
    select choice in "${options[@]}"; do
      if [[ -n "$choice" ]]; then
        echo "$choice" >&3
        return
      fi

      echo "$default" >&3
    done
  } 3>&1 1>&2
}

: <<'DOC'
  Performs the work to set up the binding between Kaitos and the user's game engine of choice.
DOC
function bind_engine() {
  local engine="$1"
  log "Binding $engine"
}

main "$@"