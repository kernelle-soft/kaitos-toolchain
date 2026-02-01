#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Orchestrates running coverage and saving the data out as a Cobertura file. Not generally for manual use.

Usage: coverage.sh [flags...]

Flags:
  -h, --help      Show this help text.

EOF
)"

function main() {
  parse_args "$@"
  mkdir -p "$REPO_ROOT/coverage" "$REPO_ROOT/temp"

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

function is_main_branch() {
  local branch
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  [[ "$branch" == "main" || "$branch" == "master" ]]
}

function has_go_changes() {
  # Always run coverage on main branch
  is_main_branch && return 0
  ! git diff --quiet origin/main...HEAD -- go/ 2>/dev/null
}

function has_rust_changes() {
  # Always run coverage on main branch
  is_main_branch && return 0
  ! git diff --quiet origin/main...HEAD -- crates/ 2>/dev/null
}

function run_go_coverage() {
  local path_tempfile path_cobertura

  path_tempfile="$REPO_ROOT/temp/go_coverage.out"
  path_cobertura="$REPO_ROOT/coverage/go_coverage.xml"

  log_banner "Go Coverage"

  cd "$REPO_ROOT/go"
  go test -coverprofile="$path_tempfile" ./...
  gocover-cobertura < "$path_tempfile" > "$path_cobertura"
}

function run_rust_coverage() {
  log_banner "Rust Coverage"
  cargo llvm-cov \
    --cobertura \
    --manifest-path "$REPO_ROOT/crates/Cargo.toml" \
    --output-path "$REPO_ROOT/coverage/rust_coverage.xml"
}

main "$@"
