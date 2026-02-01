#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
This CLI is used to orchestrate the release build of Kaitos.

Usage: build.sh [flags...]

Flags:
  -r, --rust-only     Do a release build of only the rust binaries
  -g, --go-only       Do a release build of only the go binary
  -h, --help          Show this help text.

Notes:
  This script builds for the current system's OS and architecture.
EOF
)"

import "$REPO_ROOT/scripts/shared/manifest.api.sh"

FLAG_RUST=true
FLAG_GO=true

function main() {
  parse_args "$@"

  mkdir -p "$REPO_ROOT/dist"

  if [[ $FLAG_GO = true ]] && ! build_go; then
    log "Ran into issues building go..."
    exit 1
  fi

  if [[ $FLAG_RUST = true ]] && ! build_rust; then
    log "Ran into issues building rust..."
    exit 1
  fi

  if ! bundle; then
    log "Ran into issues bundling build artifacts..."
    exit 1
  fi
}

function build_go() {
  cd "$REPO_ROOT/go"
  go build -o "$REPO_ROOT/dist/kaitos" "./cmd/kaitos.go"
  cd "$REPO_ROOT"
}

function build_rust() {
  cargo build \
    --manifest-path "$REPO_ROOT/crates/Cargo.toml" \
    --package godot \
    --release

  mkdir -p "$REPO_ROOT/dist/lib"
  cp "$REPO_ROOT/crates/target/release/libgodot.so" \
    "$REPO_ROOT/dist/lib/"
}

function bundle() {
  local version artifact_name arch
  version="$(manifest_get latest)"
  arch="$(uname -m)"
  artifact_name="kaitos-${version}-linux-${arch}"

  cd "$REPO_ROOT"
  mv dist "$artifact_name"
  tar -czvf "$artifact_name.tar.gz" "$artifact_name"

  echo "artifact_name=${artifact_name}" >> "${GITHUB_OUTPUT:-/dev/null}"
}

: <<'DOC'
  Parses CLI flags. 
  See USAGE for flag descriptions.
DOC
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
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
