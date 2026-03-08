#!/usr/bin/env bash
set -euo pipefail
source "$SHOCK_DIR/.envrc"

USAGE="$(cat <<EOF
Syncs up environment setup information from the project manifest.

Usage: sync_envrc.sh [args...]

Flags:
  -gv, --godot-version <version>
    Sets the godot engine version to <version> in the environment file.
    By default, the engine version will be pulled from the project manifest.

  -gu, --godot-url <url>
    Sets the godot download url to <url> in the environment file.
    By default, the url will be pulled from the project manifest.

  -h, --help                  Show this help text.

EOF
)"

import \
  "$PROJ/shell/.shock/lib/manifest.api.sh" \
  "$PROJ/shell/.shock/lib/envrc.api.sh" \
  "$PROJ/shell/scripts/lib/compatibility.api.sh"

__sync_envrc__ARG_GODOT_URL=""
__sync_envrc__ARG_GODOT_VERSION=""

function main() {
  parse_args "$@"

  if [[ -z "$__sync_envrc__ARG_GODOT_URL" ]]; then
    __sync_envrc__ARG_GODOT_URL="$(manifest_get godot_url)"
  fi

  if [[ -z "$__sync_envrc__ARG_GODOT_VERSION" ]]; then
    __sync_envrc__ARG_GODOT_VERSION="$(manifest_get godot_version)"
  fi

  if ! is_supported_engine_version godot "$__sync_envrc__ARG_GODOT_VERSION"; then
    error "Godot version '$__sync_envrc__ARG_GODOT_VERSION' is not in the supported versions list."
    exit 1
  fi

  envrc_set godot_url "$__sync_envrc__ARG_GODOT_URL"
  envrc_set godot_version "$__sync_envrc__ARG_GODOT_VERSION"

  log "Project environment is up-to-date."
}

: <<'DOC'
  Parses CLI flags.
  See USAGE for flag descriptions.
DOC
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -gv|--godot-version)
        shift;
        __sync_envrc__ARG_GODOT_VERSION="$1"
        ;;
      -gu|--godot-url)
        shift
        __sync_envrc__ARG_GODOT_URL="$1"
        ;;
      -h|--help)  log "$USAGE" && exit 0;;
      *)
        log "Unknown option: $1"
        log "$USAGE"
        exit 1
        ;;
    esac
    shift
  done
}

main "$@"
