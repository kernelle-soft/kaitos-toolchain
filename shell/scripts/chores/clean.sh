#!/usr/bin/env bash
set -euo pipefail
source "$SHOCK_DIR/.envrc"

USAGE="$(cat <<EOF
Clean up the project of various temp folders and artifacts.

Usage: clean.sh [flags...]

Flags:
  -a, --all         Do all optional cleanup.
  -b, --build       Delete the build folder.
  -c, --coverage    Delete the coverage folder.
  -d, --docs        Clean up the build artifacts for the docsite.
  -g, --go          Delete any local go builds.
  -r, --rust        Delete rust target folders.
  -h, --help        Show this help text.

EOF
)"

FLAG_BUILD=false
FLAG_COVERAGE=false
FLAG_RUST=false
FLAG_GO=false
FLAG_DOCS=false

function main() {
  parse_args "$@"

  rm -rf "$PROJ/temp"
  rm -rf "$PROJ/tmp"
  rm -rf "$PROJ"/kaitos-*-linux-*
  rm -rf "$PROJ"/kaitos-*.tar.gz

  if [[ $FLAG_BUILD = true ]]; then
    rm -rf "$PROJ/build/" "$PROJ/dist/"
  fi

  if [[ $FLAG_COVERAGE = true ]]; then
    rm -rf "$PROJ/coverage/"
  fi

  if [[ $FLAG_RUST = true ]]; then
    shopt -s globstar nullglob
    rm -rf "$PROJ"/crates/**/target/
    shopt -u globstar nullglob
  fi

  if [[ $FLAG_GO = true ]]; then
    rm -f "$PROJ/go/kaitos"
  fi

  if [[ $FLAG_DOCS = true ]]; then
    rm -rf \
      "$PROJ/site/.astro" \
      "$PROJ/site/dist"
  fi
}

: <<'DOC'
  Parses CLI flags.
  See USAGE for flag descriptions.
DOC
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -a|--all)
        FLAG_BUILD=true
        FLAG_COVERAGE=true
        FLAG_RUST=true
        FLAG_GO=true
        FLAG_DOCS=true
        ;;
      -b|--build)
        FLAG_BUILD=true
        ;;
      -c|--coverage)
        FLAG_COVERAGE=true
        ;;
      -d|--docs)
        FLAG_DOCS=true
        ;;
      -g|--go)
        FLAG_GO=true
        ;;
      -r|--rust)
        FLAG_RUST=true
        ;;
      -h|--help)
        log "$USAGE"
        exit 0
        ;;
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