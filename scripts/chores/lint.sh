#!/usr/bin/env bash
set -euo pipefail
eval "${SHELLSHOCK_ENVRC:-}"

USAGE="$(cat <<EOF
Handler for checking project linting in CI/CD & commit hooks.

Usage: lint.sh [flags...]

Flags:
  -h,--help     Show this help text.
  -r,--rust     Lint and check formatting for rust only.
  -g,--go       Lint and check formatting for go only.

Notes:
  If you'd like to check for linting before commit automatically,
  I strongly recommend installing lefthook. Instructions are in
  the README, or check out https://lefthook.dev
EOF
)"

import "$PROJ/scripts/shared/lint.api.sh"

FLAG_RUST=true
FLAG_GO=true

function main() {
  parse_args "$@"

  if [[ $FLAG_GO = true ]]; then
    lint_go
  fi

  if [[ $FLAG_RUST = true ]]; then
    lint_rust
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
