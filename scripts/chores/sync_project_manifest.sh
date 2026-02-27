#!/usr/bin/env bash
set -euo pipefail
eval "${SHELLSHOCK_ENVRC:-}"

USAGE="$(cat <<EOF
Syncs up the project manifest based on the latest in git.

Usage: sync_project_manifest.sh [version]

Arguments:
  version         Optional version to set as latest. If not provided, the latest
                  version will be determined from git tags.

Flags:
  -h, --help      Show this help text.

EOF
)"

ARG_VERSION=""

import \
  "$PROJ/scripts/shared/versions.api.sh" \
  "$PROJ/scripts/shared/manifest.api.sh"

function main() {
  local latest
  parse_args "$@"
  if [[ -z "$ARG_VERSION" ]]; then
    fatal "version not supplied"
    log "$USAGE"
    exit 1
  fi

  if ! is_valid_semver "$ARG_VERSION"; then
    fatal "The version supplied is not valid semver. Received: '$ARG_VERSION'"
    exit
  fi

  latest="$ARG_VERSION"
  manifest_set latest "$latest"

  if is_release_version "$latest"; then
    manifest_set stable "$latest"
    manifest_set releases $(($(manifest_get releases) + 1))
  else
    manifest_set stable "$(latest_release_version)"
  fi

  log "Synced project manifest to $(manifest_get latest)"
}

: <<'DOC'
  Parses CLI flags.
  See USAGE for flag descriptions.
DOC
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)  log "$USAGE" && exit 0;;
      -*)
        log "Unknown option: $1"
        log "$USAGE"
        exit 1
        ;;
      *)
        ARG_VERSION="$1"
        ;;
    esac
    shift
  done
}

main "$@"