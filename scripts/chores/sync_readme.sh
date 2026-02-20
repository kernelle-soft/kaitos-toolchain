#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Syncs up the README to the current project manifest and version.

This script updates the README with:
  - Pokemon sprite and name based on release count
  - Lines of code from tokei
  - Coverage percentages from Codecov (requires CODECOV_TOKEN)

Usage: sync_readme.sh [options] [version]

Arguments:
  version           Optional version tag (e.g., 0.1.0). If not provided,
                    pulls from manifest.

Flags:
  -h, --help        Show this help text.

EOF
)"

import \
  "$KAITOSHOME/scripts/shared/poke.api.sh"

ARG_VERSION=""

function main() {
  # shellcheck disable=SC2034
  # - using namerefs throughout function, shellcheck doesn't catch that.
  local -A poke_info
  parse_args "$@"

  log "Gathering pokedex entry data..."
  get_pokedex_entry poke_info "$ARG_VERSION"

  log "Updating README..."
  update_readme poke_info

  log "README sync complete."
}

: <<'DOC'
  Updates the README's pokedex section with new content.
  Uses awk to replace everything between POKE_START and POKE_END markers.
DOC
function update_readme() {
  local -n __poke__="$1"
  local readme_file new_content tmp_file

  readme_file="$KAITOSHOME/README.md"
  tmp_file="$(mktemp)"
  new_content="$(generate_pokedex_entry __poke__)"

  awk -v new_content="$new_content" -v start="$POKE_START" -v end="$POKE_END" '
    $0 ~ start { in_block = 1; print new_content; next }
    $0 ~ end   { in_block = 0; next }
    !in_block  { print }
  ' "$readme_file" > "$tmp_file"

  mv "$tmp_file" "$readme_file"
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