#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

USAGE="$(cat <<EOF
Orchestrates unit testing for the project.

Usage: unit_tests.sh [flags...]

Flags:
  -h, --help          Shows this help text
  -r, --rust-only     Run exclusively rust unit tests
  -g, --go-only       Run exclusively go unit tests
  -f, --filter <str>  
EOF
)"

source "$REPO_ROOT/scripts/shared/log.func.sh"

FLAG_RUST=true
FLAG_GO=true
STR_FILTER=""

BANNER_RUST="$(cat <<EOF
-------------------------------
- Rust Unit Tests             -
-------------------------------
EOF
)"

BANNER_GO="$(cat <<EOF
-------------------------------
- Go Unit Tests               -
-------------------------------
EOF
)"

function main() {
  parse_args "$@"

  if [[ $FLAG_RUST = true ]]; then
    run_rust_tests "$STR_FILTER"
  fi

  if [[ $FLAG_GO = true ]]; then
    run_go_tests "$STR_FILTER"
  fi
}

: <<'DOC'
	Parses CLI flags. 
	See USAGE for flag descriptions.
DOC
function parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
      -f|--filter)
        shift
        STR_FILTER=""
        ;;
      -r|--rust-only)
        FLAG_GO=false
        ;;
      -g|--go-only)
        FLAG_RUST=false
        ;;
			-h|--help)	
        log "$USAGE" && exit 0
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

: <<'DOC'
Runs the rust unit test suite for the project.

Args:
1. filter - The filter to pass to the rust unit tester
DOC
function run_rust_tests() {
  local filter

  filter="$1"
  if [[ -z "$filter" ]]; then
    log "$BANNER_RUST\n"
  fi

  log "TODO: rust unit tests"
}

: <<'DOC'
Rust the go unit test suite for the project.

Args:
1. filter - The filter to pass to the go unit tester
DOC
function run_go_tests() {
  local filter

  filter="$1"
  if [[ -z "$filter" ]]; then
    log "$BANNER_GO\n"
  fi

  log "TODO: go unit tests"
}

main "$@"