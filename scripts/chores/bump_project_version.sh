#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

USAGE="$(cat <<EOF

Flags:
  -h, --help      Show this help text.

EOF
)"

source "$REPO_ROOT/scripts/shared/log.func.sh"
source "$REPO_ROOT/scripts/shared/git/latest_version.func.sh"
source "$REPO_ROOT/scripts/shared/git/parse_version.func.sh"

PROJECT_MANIFEST="$REPO_ROOT/project.json"

function main() {
  local git_version

  parse_args "$@"
  
  git_version="$(latest_version)"
  
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

  jq .series_name "$PROJECT_MANIFEST"
}

function is_before_v1() {
  jq -e '.version | startswith("0.")' "$PROJECT_MANIFEST" > /dev/null
}

function get_pokemon_name() {
  local pokemon_name index api_response
  index="$(jq .successful_releases < "$PROJECT_MANIFEST")"
  api_response="$(curl -s "https://pokeapi.co/api/v2/pokemon/$index")"
  pokemon_name="$(jq -r '.name' <<< "$api_response" | sed 's/.*/\u&/')"

  echo "$pokemon_name"
}

main "$@"

#TODO: Pokemonify