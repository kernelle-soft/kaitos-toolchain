#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

USAGE="$(cat <<EOF
Orchestrates running coverage and saving the data out as a Cobertura file. Not generally for manual use.

Usage: cicd_coverage.sh [flags...]

Flags:
  -h, --help      Show this help text.

EOF
)"

source "$REPO_ROOT/scripts/shared/log.func.sh"
source "$REPO_ROOT/scripts/shared/log_banner.func.sh"

function main() {
  parse_args "$@"

  if has_go_changes; then
    run_go_coverage
  fi

  if has_rust_changes; then
    run_rust_coverage
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

function has_go_changes() {
  git diff --name-only origin/main...HEAD -- go/ 1>&2 2>/dev/null
}

function has_rust_changes() {
  git diff --name-only origin/main...HEAD -- crates/ 1>&2 2>/dev/null
}

function run_go_coverage() {
  log_banner "Go Coverage"
  go test -coverprofile=temp/go_coverage.out ./...
  gocover-cobertura < temp/go_coverage.out > go_coverage.xml
}

function run_rust_coverage() {
  log_banner "Rust Coverage"
}

main "$@"