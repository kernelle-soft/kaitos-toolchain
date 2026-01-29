#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

USAGE="$(cat <<EOF
Orchestrates unit testing for the project. Not generally for manual use.

Usage: unit_tests.sh [flags...]

Flags:
  -h, --help          Shows this help text
  -r, --rust-only     Run exclusively rust unit tests
  -g, --go-only       Run exclusively go unit tests

Notes: 
  If you need more granularity for running tests, 
  use the toolchains for each language.
EOF
)"

source "$REPO_ROOT/scripts/shared/log.func.sh"

FLAG_RUST=true
FLAG_GO=true

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
    run_rust_tests
  fi

  if [[ $FLAG_GO = true ]]; then
    run_go_tests
  fi
}

: <<'DOC'
  Parses CLI flags. 
  See USAGE for flag descriptions.
DOC
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
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
DOC
function run_rust_tests() {
  log "$BANNER_RUST\n"
  cargo test --manifest-path "$REPO_ROOT/crates/Cargo.toml"
}

: <<'DOC'
Runs the go unit test suite for the project.
DOC
function run_go_tests() {
  log "$BANNER_GO\n"
  go test -v ./go/...
}

main "$@"