#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Orchestrates compilation and deployment of Kaitos.

Usage: build.sh [flags...]

Flags:
  -R, --release       Build in release mode (optimized, enables bundling)
  -l, --local         Deploy to dist/ instead of system XDG locations
  -r, --rust-only     Build only the Rust binaries
  -g, --go-only       Build only the Go binary
  -h, --help          Show this help text

Default: dev mode, system deploy (debug build installed to XDG locations)
EOF
)"

import \
  "$REPO_ROOT/scripts/shared/compile.api.sh" \
  "$REPO_ROOT/scripts/shared/deploy.api.sh"

FLAG_RUST=true
FLAG_GO=true
FLAG_RELEASE=false
FLAG_LOCAL=false

function main() {
  parse_args "$@"

  declare -A compile_opts=()
  if [[ $FLAG_RELEASE = true ]]; then
    compile_opts[release]=true
  fi

  mkdir -p "$REPO_ROOT/dist"

  if [[ $FLAG_GO = true ]] && ! compile_go compile_opts; then
    log "Ran into issues compiling go..."
    exit 1
  fi

  if [[ $FLAG_RUST = true ]] && ! compile_rust compile_opts; then
    log "Ran into issues compiling rust..."
    exit 1
  fi

  if [[ $FLAG_LOCAL = true ]]; then
    deploy_local
    if [[ $FLAG_RELEASE = true ]]; then
      bundle
    fi
  else
    if ! deploy_system; then
      log "Ran into issues deploying to system..."
      exit 1
    fi
  fi
}

: <<'DOC'
  Parses CLI flags.
  See USAGE for flag descriptions.
DOC
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -R|--release)
        FLAG_RELEASE=true
        ;;
      -l|--local)
        FLAG_LOCAL=true
        ;;
      -g|--go-only)
        FLAG_RUST=false
        ;;
      -r|--rust-only)
        FLAG_GO=false
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
