#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Syncs up the README to the current project manifest and version

Flags:
  -h, --help        Show this help text.

EOF
)"

function main() {
  local -A pokemon
  parse_args "$@"

  get_pokemon pokemon


}


: <<'DOC'
Pulls down information on a given pokemon based on the number of successful releases of this project.
DOC
function get_pokemon() {
  local url api_response release_count static_image_url
  local -A __poke__

  static_image_url="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown"

  release_count="$(manifest_get releases)"
  if [[ -z  "$release_count" || $release_count == "0" ]]; then
    __poke__[idx]="???"
    __poke__[name]="Unown"
    __poke__[image]="$static_image_url/unown-question.gif"
    return
  fi

  url="https://pokeapi.co/api/v2/pokemon/$release_count"
  if ! api_response="$(curl -s "$url")"; then
    log "Failed to get response from PokeAPI, using fallback"
    __poke__[idx]="???"
    __poke__[name]="Unown"
    __poke__[image]="$static_image_url/unown-o.gif"
    return
  fi

  __poke__[idx]="$release_count"
  __poke__[name]="$(jq '.name' <<< "$api_response")"
  __poke__[image]="$(jq '.sprites.other.showdown.front_default' <<< "$api_response")"
  if [[ -z "${__poke__[image]}" ]]; then
    __poke__[image]="$(jq '.sprites.front_default' <<< "$api_response")"
  fi

  if [[ -z "${__poke__[image]}" ]]; then
    __poke__[image]="$static_image_url/unown-x.gif"
  fi
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

main "$@"