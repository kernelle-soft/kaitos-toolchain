#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Syncs up the project manifest (kaitos.json) based on the latest in git.

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
  "$REPO_ROOT/scripts/shared/versions.api.sh" \
  "$REPO_ROOT/scripts/shared/manifest.api.sh"

function main() {
  parse_args "$@"

  local latest_version
  if [[ -n "$ARG_VERSION" ]]; then
    latest_version="$ARG_VERSION"
  else
    latest_version="$(plan_latest_version_bump)"
  fi

  manifest_set latest "$latest_version"
  manifest_set releases "$(plan_releases_bump)"

  if is_release_version "$latest_version"; then
    manifest_set stable "$latest_version"
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

: <<'DOC'
  Plans the latest version bump based on the latest version in git and the latest version in the manifest.
DOC
function plan_latest_version_bump() {
  local manifest_latest git_latest result
  git_latest="$(latest_version)"
  manifest_latest="$(manifest_get latest)"

  # If git version is latest, then update latest version
  result="$(compare_versions "$git_latest" "$manifest_latest")"
  if [[ "$result" = -1 ]]; then
    manifest_latest="$git_latest"
  fi

  echo "$manifest_latest"
}

: <<'DOC'
  Plans the releases bump based on the latest release version in git and the latest release version in the manifest.
DOC
function plan_releases_bump() {
  local manifest_releases git_stable manifest_stable

  manifest_releases="$(manifest_get releases)"

  git_stable="$(latest_release_version)"
  manifest_stable="$(manifest_get stable)"

  if [[ "$(compare_versions "$git_stable" "$manifest_stable")" = -1 ]]; then
    manifest_releases=$((manifest_releases + 1))
  fi

  echo "$manifest_releases"
}

main "$@"