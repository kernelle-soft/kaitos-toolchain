#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

USAGE="$(cat <<EOF
Syncs the project version to the git version

Flags:
  -h, --help      Show this help text.

EOF
)"

source "$REPO_ROOT/scripts/shared/log.func.sh"
source "$REPO_ROOT/scripts/shared/git/latest_version.func.sh"
source "$REPO_ROOT/scripts/shared/git/parse_version.func.sh"

PROJECT_MANIFEST="$REPO_ROOT/project.json"

function main() {
  local git_version updated_latest_version updated_latest_release

  parse_args "$@"
  
  git_version="$(latest_version)"
  updated_latest_version="$(plan_latest_version)"
  updated_latest_release="$(plan_latest_release)"
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

function get_release_name() {
  if is_before_v1; then
    get_pokemon_name
    return 0
  fi

  jq -r '.series_name' "$PROJECT_MANIFEST"
}

function is_before_v1() {
  jq -e '.version | startswith("0.")' "$PROJECT_MANIFEST" > /dev/null
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
  local latest_version git_version
  git_version="$(latest_version)"
  latest_version="$(jq .latest_version < "$PROJECT_MANIFEST")"

  # If git version is latest, then update latest version
  # TODO: use new git comparison function to determine version supremacy
  if [[ ]]
}

function plan_latest_release_update() {
  local git_version latest_release git_release
  git_version="$(latest_version)"
  git_release="$(latest_release_version)"
  project_latest_release="$(jq .latest_release < "$PROJECT_MANIFEST")"

  # If the newest git version isn't pre-release

}

main "$@"

#TODO: Pokemonify