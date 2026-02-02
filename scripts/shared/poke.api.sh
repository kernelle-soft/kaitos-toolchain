#!/usr/bin/env bash
eval "${CI_ENVRC:-}"

import "$REPO_ROOT/scripts/shared/manifest.api.sh"

export POKE_START="<!--POKE_INFO_START-->"
export POKE_END="<!--POKE_INFO_END-->"

function generate_pokedex_entry() {
  local -n __poke_info__="$1"

  cat <<EOF
$POKE_START
<div id="poke-info" align="center">
  <h3>
    If Kaitos' latest stable release was a Pokémon,
    <br>
    it would be...
  </h3>
  <img
    id="pokemon-img"
    src="${__poke_info__[image]}"
  />
  <br>
  <span id="pokemon-name"><b>Release #${__poke_info__[release_number]}: ${__poke_info__[tag]} - ${__poke_info__[name]}</b></span>
  <br>
  <img
    id="rust-runtime-coverage"
    src="https://img.shields.io/codecov/c/github/kernelle-soft/kaitos-toolchain?flag=rust&label=Rust"
  />
  <img
    id="go-cli-coverage"
    src="https://img.shields.io/codecov/c/github/kernelle-soft/kaitos-toolchain?flag=go&label=Go"
  />
  <img
    id="security-checks"
    src="https://github.com/kernelle-soft/kaitos-toolchain/actions/workflows/_security.yaml/badge.svg?branch=main"
    alt="Security Checks"
  />
  <br>
  <span>Base Stats</span>
  <table align="center">
    <tr>
      <th>Lang</th>
      <th>Lines of Code</th>
      <th>Unit Test Coverage</th>
      <th>Coverage Type</th>
    </tr>
    <tr>
      <td>Go</td>
      <td>${__poke_info__[go_loc]}</td>
      <td>${__poke_info__[go_unit_coverage]}</td>
      <td>Branch</td>
    </tr>
    <tr>
      <td>Rust</td>
      <td>${__poke_info__[rust_loc]}</td>
      <td>${__poke_info__[rust_unit_coverage]}</td>
      <td>Branch</td>
    </tr>
    <tr>
      <td>Bash</td>
      <td>${__poke_info__[bash_loc]}</td>
      <td>N/A</td>
      <td>N/A</td>
    </tr>
  </table>
</div>
$POKE_END
EOF
}

: <<'DOC'
  Populates a nameref associative array with all data needed for generate_pokedex_entry.

  Usage:
    local -A poke_info
    get_pokedex_entry poke_info [version]

  Arguments:
    poke_info   Nameref to associative array to populate
    version     Optional version string (e.g., "0.1.0"). If not provided,
                pulls from manifest.
DOC
function get_pokedex_entry() {
  local -n __poke_info__="$1"
  local version="${2:-}"

  __poke_api__get_pokemon __poke_info__ "$version"
  __poke_api__get_loc __poke_info__
  __poke_api__get_coverage __poke_info__
}

# ════════════════════════════════════════════════════════════════════════════
# Internal helpers
# ════════════════════════════════════════════════════════════════════════════

__poke_api__sprite_base="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown"

: <<'DOC'
  Fetches Pokemon info from PokeAPI based on release count.
  Sets: release_number, name, image, tag

  Arguments:
    out       Nameref to associative array
    version   Optional version override (uses manifest if empty)
DOC
function __poke_api__get_pokemon() {
  local -n __out__="$1"
  local version="${2:-}"
  local api_response release_count url

  release_count="$(manifest_get releases)"
  __out__[tag]="v$(manifest_get stable)"

  if [[ -z "$release_count" || "$release_count" == "0" ]]; then
    __out__[release_number]="???"
    __out__[name]="Unown"
    __out__[image]="$__poke_api__sprite_base/unown-question.gif"
    return
  fi

  __out__[release_number]="$release_count"

  url="https://pokeapi.co/api/v2/pokemon/$release_count"
  if ! api_response="$(curl -sf "$url")"; then
    log "Failed to get response from PokeAPI, using fallback"
    __out__[name]="Unown"
    __out__[image]="$__poke_api__sprite_base/unown-o.gif"
    return
  fi

  # Extract name (capitalize first letter)
  __out__[name]="$(jq -r '.name | split("") | .[0] |= ascii_upcase | join("")' <<< "$api_response")"
  if [[ -z "${__out__[name]:-}" ]]; then
    __out__[name]="Unown"
  fi

  # Extract image (prefer showdown animated sprite, fall back to default)
  __out__[image]="$(jq -r '.sprites.other.showdown.front_default // empty' <<< "$api_response")"
  if [[ -z "${__out__[image]:-}" ]]; then
    __out__[image]="$(jq -r '.sprites.front_default // empty' <<< "$api_response")"
  fi

  # Global image fallback if both image paths fail.
  if [[ -z "${__out__[image]:-}" ]]; then
    __out__[image]="$__poke_api__sprite_base/unown-x.gif"
  fi
}

: <<'DOC'
  Gets lines of code from tokei.
  Sets: go_loc, rust_loc, bash_loc
DOC
function __poke_api__get_loc() {
  local -n __out__="$1"
  local tokei_json

  tokei_json="$(tokei --output json "$REPO_ROOT")"

  __out__[go_loc]="$(jq -r '.Go.code // 0' <<< "$tokei_json")"
  __out__[rust_loc]="$(jq -r '.Rust.code // 0' <<< "$tokei_json")"
  __out__[bash_loc]="$(jq -r '.Shell.code // 0' <<< "$tokei_json")"
}

: <<'DOC'
  Fetches coverage percentages from Codecov API.
  Requires CODECOV_API_TOKEN environment variable.
  Sets: go_unit_coverage, rust_unit_coverage, bash_unit_coverage
DOC
function __poke_api__get_coverage() {
  local -n __out__="$1"
  local org repo codecov_base

  org="$(manifest_get org)"
  repo="$(manifest_get repo)"
  codecov_base="https://api.codecov.io/api/v2/github/$org/repos/$repo/totals"

  if [[ -n "${CODECOV_API_TOKEN:-}" ]]; then
    __out__[go_unit_coverage]="$(__poke_api__fetch_coverage "$codecov_base" "go")"
    __out__[rust_unit_coverage]="$(__poke_api__fetch_coverage "$codecov_base" "rust")"
  else
    log "CODECOV_API_TOKEN not set, coverage will show N/A"
    __out__[go_unit_coverage]="N/A"
    __out__[rust_unit_coverage]="N/A"
  fi
}

: <<'DOC'
  Fetches coverage for a specific flag from Codecov.
  Outputs the coverage percentage or "N/A" on failure.

  Usage: __poke_api__fetch_coverage <base_url> <flag>
DOC
function __poke_api__fetch_coverage() {
  local base_url="$1"
  local flag="$2"
  local result

  if result="$(curl -sf -H "Authorization: Bearer $CODECOV_API_TOKEN" "$base_url/?flag=$flag")"; then
    jq -r '(.totals.coverage // 0 | floor | tostring) + "%"' <<< "$result"
  else
    echo "N/A"
  fi
}