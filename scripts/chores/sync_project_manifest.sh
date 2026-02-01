#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Syncs up the project manifest (kaitos.json) based on the latest in git.

Usage: sync_project_manifest.sh

Flags:
  -h, --help      Show this help text.

EOF
)"

import \
  "$REPO_ROOT/scripts/shared/versions.api.sh" \
  "$REPO_ROOT/scripts/shared/manifest.api.sh"


function main() {
  parse_args "$@"

  manifest_set latest "$(plan_latest_version_bump)"
  manifest_set releases "$(plan_releases_bump)"
  manifest_set stable "$(latest_release_version)"
  manifest_set release-nickname "$(get_pokemon_name)"

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
      *)
        log "Unknown option: $1"
        log "$USAGE"
        exit 1
        ;;
    esac
    shift
  done
}

: <<'DOC'
  Gets the release nickname for the latest release using the release count to index into the Pokedex.
DOC
function get_pokemon_name() {
  local url pokemon_name api_response release_count

  release_count="$(manifest_get releases)"
  if [[ -z  "$release_count" || $((release_count == 0)) ]]; then
    echo ""
    return
  fi

  url="https://pokeapi.co/api/v2/pokemon/$release_count"
  if ! api_response="$(curl -s "$url")"; then
    log "Failed to get response from PokeAPI"
    echo ""
    return
  fi

  pokemon_name="$(jq -r '.name' <<< "$api_response")"
  pokemon_name="${pokemon_name^}" # Uppercase first letter.

  echo "$pokemon_name"
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