#!/usr/bin/env bash
set -euo pipefail
eval "${SHELLSHOCK_ENVRC:-}"

USAGE="$(cat <<EOF
Syncs the docs site version (site/package.json) to the canonical project version.

Usage: sync_docs_version.sh [version]

Arguments:
  version     Optional semver version to use (e.g., 1.2.3 or 1.0.0-rc.1)
              If not provided, reads the current version from git tags.

Flags:
  -h, --help  Show this help text
EOF
)"

ARG_VERSION=""

import "$PROJ/scripts/shared/versions.api.sh"

PATH_DOCS_PACKAGE="$PROJ/site/package.json"

function main() {
  local current_version old_version

  parse_args "$@"

  if [[ -n "$ARG_VERSION" ]]; then
    current_version="$ARG_VERSION"
  else
    current_version="$(latest_version)"
  fi

  old_version="$(jq -r '.version' "$PATH_DOCS_PACKAGE")"

  if [[ "$current_version" = "$old_version" ]]; then
    log "Docs site is up-to-date with version '$current_version'"
    exit 0
  fi

  local temp_file
  temp_file="$(mktemp)"
  jq --arg v "$current_version" '.version = $v' "$PATH_DOCS_PACKAGE" > "$temp_file"
  mv "$temp_file" "$PATH_DOCS_PACKAGE"

  log "Successfully updated site/package.json to '$current_version'"
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
        if ! is_valid_semver "$1"; then
          log "Invalid semver: $1"
          log "$USAGE"
          exit 1
        fi
        ARG_VERSION="$1"
        ;;
    esac
    shift
  done
}

main "$@"
