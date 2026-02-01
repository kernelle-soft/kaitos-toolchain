#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Clean up the project of various temp folders and artifacts.

Usage: clean.sh [flags...]

Flags:
  -a, --all         Do all optional cleanup.
  -b, --build       Delete the build folder.
  -c, --coverage    Delete the coverage folder.
  -g, --go          Delete any local go builds.
  -r, --rust        Delete rust target folders. 
  -h, --help        Show this help text.

EOF
)"

FLAG_BUILD=false
FLAG_COVERAGE=false
FLAG_RUST=false
FLAG_GO=false

function main() {
  parse_args "$@"

  rm -rf "$REPO_ROOT/temp"
  rm -rf "$REPO_ROOT/tmp"
  rm -rf "$REPO_ROOT"/kaitos-*-linux-*
  rm -rf "$REPO_ROOT"/kaitos-*.tar.gz

  [[ $FLAG_BUILD = true ]] && \
    rm -rf "$REPO_ROOT/build/" "$REPO_ROOT/dist/"

  [[ $FLAG_COVERAGE = true ]] && \
    rm -rf "$REPO_ROOT/coverage/"

  if [[ $FLAG_RUST = true ]]; then
    shopt -s globstar nullglob
    rm -rf "$REPO_ROOT"/crates/**/target/
    shopt -u globstar nullglob
  fi

  [[ $FLAG_GO = true ]] && \
    rm -f "$REPO_ROOT/go/kaitos"
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
        ;;
      -b|--build)
        FLAG_BUILD=true
        ;;
      -c|--coverage)
        FLAG_COVERAGE=true
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