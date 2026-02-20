#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Pulls the latest version of the repository from git and applies it to the Cargo workspace version.

Usage: sync_cargo_version.sh [version]

Arguments:
  version     Optional semver version to use (e.g., 1.2.3 or 1.0.0-rc.1)
              If not provided, reads the current version from git tags.

Flags:
  -h, --help  Show this help text
EOF
)"

ARG_VERSION=""
REGEX_SEMVER='^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z]+(\.[0-9]+)?)?$'

import "$REPO_ROOT/scripts/shared/versions.api.sh"

PATH_CARGO_WORKSPACE="$REPO_ROOT/crates/Cargo.toml"

function main() {
  local current_version old_version_line new_version_line

  parse_args "$@"

  if [[ -n "$ARG_VERSION" ]]; then
    current_version="$ARG_VERSION"
  else
    current_version="$(latest_version)"
  fi
  new_version_line="$(format_version_line "$current_version")"
  old_version_line="$(get_cargo_workspace_version)"

  if [[ "$new_version_line" = "$old_version_line" ]]; then
    log "Cargo workspace is up-to-date with latest version '$current_version'"
    exit 0
  fi

  replace_workspace_version "$old_version_line" "$new_version_line"
  sync_lockfile "$current_version"
  log "Successfully updated Cargo.toml to '$current_version'"
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
        if [[ ! "$1" =~ $REGEX_SEMVER ]]; then
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

: <<'DOC'
Gets a clean semver string from the workspace Cargo.toml file.

This includes stripping any quote literals and leading characters,
returning just the version itself.

If none is specified, defaults to "0.0.0"
DOC
function get_cargo_workspace_version() {
  local version=""
  local found_workspace_package=false

  # Walks through the Cargo.toml line by line
  while IFS= read -r line; do
    if [[ "$line" == "[workspace.package]" ]]; then
      found_workspace_package=true

    elif [[ "$line" == "["* ]]; then
      found_workspace_package=false

    elif $found_workspace_package && [[ "$line" == version* ]]; then
      version="$line"
      break

    fi
  done < "$PATH_CARGO_WORKSPACE"

  if [[ -n "$version" ]]; then
    echo "$version"
  else
    format_version_line "0.0.0"
  fi
}

function format_version_line() {
  echo "version = \"$1\""
}

function replace_workspace_version() {
  local previous_version next_version

  previous_version="$1"
  next_version="$2"

  sed -i "s/$previous_version/$next_version/" "$PATH_CARGO_WORKSPACE"
}

: <<'DOC'
Lists the names of all crates in the Cargo workspace.
Uses mapfile (bash 4+ builtin) to populate the provided
array variable via nameref.
DOC
function get_workspace_packages() {
  local -n __packages__="$1"

  mapfile -t __packages__ < <(
    cargo metadata \
      --manifest-path "$PATH_CARGO_WORKSPACE" \
      --no-deps \
      --format-version 1 \
      | jq -r '.packages[].name'
  )
}

: <<'DOC'
Updates Cargo.lock entries for workspace members only,
without upgrading third-party dependencies.
DOC
function sync_lockfile() {
  local version="$1"
  local packages

  get_workspace_packages packages

  for pkg in "${packages[@]}"; do
    cargo update --manifest-path "$PATH_CARGO_WORKSPACE" --package "$pkg" --precise "$version"
  done
}

main "$@"
