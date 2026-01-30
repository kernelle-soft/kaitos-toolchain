#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

USAGE="$(cat <<EOF
Syncs up the project manifest (project.json) based on the latest in git.

Usage: sync_project_manifest.sh

Flags:
  -h, --help      Show this help text.

EOF
)"

source "$REPO_ROOT/scripts/shared/log.func.sh"
source "$REPO_ROOT/scripts/shared/git/latest_version.func.sh"
source "$REPO_ROOT/scripts/shared/git/parse_version.func.sh"
source "$REPO_ROOT/scripts/shared/git/compare_versions.func.sh"

PROJECT_MANIFEST="$REPO_ROOT/project.json"

function main() {
  local git_version manifest_latest updated_latest_release
  local releases

  parse_args "$@"
  
  git_version="$(latest_version)"
  manifest_latest="$(plan_latest_version)"
  updated_latest_release="$(latest_release_version)"
  releases="$(jq .successful_releases < "$PROJECT_MANIFEST")"

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

function parse_meta() {
  local -n name latest_version latest_release successful_releases series
}

function get_release_name() {
  if is_before_v1; then
    get_pokemon_name
    return 0
  fi

  jq -r '.series_name' "$PROJECT_MANIFEST"
}

function is_before_v1() {
  jq -e '.stable | startswith("0.")' "$PROJECT_MANIFEST" > /dev/null
}

function get_pokemon_name() {
  local pokemon_name index api_response
  index="$(jq -r .successful_releases < "$PROJECT_MANIFEST")"
  api_response="$(curl -s "https://pokeapi.co/api/v2/pokemon/$index")"
  pokemon_name="$(jq -r '.name' <<< "$api_response")"
  pokemon_name="${pokemon_name^}"

  echo "$pokemon_name"
}

function plan_latest_version_update() {
  local manifest_latest git_latest result
  git_latest="$(latest_version)"
  manifest_latest="$(jq .latest < "$PROJECT_MANIFEST")"

  # If git version is latest, then update latest version  
  result="$(compare_versions "$git_latest" "$manifest_latest")"
  if [[ "$result" = -1 ]]; then
    manifest_latest="$git_latest"
  fi

  echo "$manifest_latest"
}

main "$@"