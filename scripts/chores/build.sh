#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Orchestrates compilation and deployment of Kaitos.

Usage: build.sh [flags...]

Flags:
  Compile Args:
  -d, --debug
    Compile for debugging. This is the default compile behavior.

  -r, --release
    Compile for release

  -R, --rust-only
    Only compile Rust code

  -G, --go-only
    Only compile Go code

  Deployment Args:
  -s, --system
    Deploy the build artifacts at the system level (XDG compliance).
    This is the default deployment behavior.

  -p, --project
    Deploy the build artifacts at the project level (in dist/)

  -b, --bundle
    Produce a bundle of the compiled artifacts for distribution instead of deploying.

    The archive will have the following structure:
    kaitos-<version>-<platform>-<arch>.tar.gz/
      - kaitos (Go binary, entrypoint bin)
      - lib/
        - libgodot.{so,dylib}

  -h, --help
    Show this help text
EOF
)"

import \
  "$REPO_ROOT/scripts/shared/compile.api.sh" \
  "$REPO_ROOT/scripts/shared/deploy.api.sh"

FLAG_GO=true
FLAG_RUST=true
FLAG_RELEASE=false
ENUM_DEPLOY_OPTION="system"

function main() {
  parse_args "$@"

  declare -A compile_opts=()
  if [[ $FLAG_RELEASE = true ]]; then
    # shellcheck disable=SC2034
    compile_opts[release]=true
  fi

  mkdir -p "$REPO_ROOT/dist"

  if [[ $FLAG_GO = true ]] && ! compile_go compile_opts; then
    error "Ran into issues compiling go..."
    exit 1
  fi

  if [[ $FLAG_RUST = true ]] && ! compile_rust compile_opts; then
    error "Ran into issues compiling rust..."
    exit 1
  fi

  case "$ENUM_DEPLOY_OPTION" in
    system)
      if ! deploy_system; then
        error "Ran into issues deploying artifacts to your system..."
        exit 1
      fi
      ;;
    project)
      if ! deploy_project; then
        error "Ran into issues deploying artifacts at the project level..."
        exit 1
      fi
      ;;
    bundle)
      if ! deploy_bundle; then
        error "Ran into issues bundling artifacts..."
        exit 1
      fi
      ;;
    *)
      error "Invalid deploy target $ENUM_DEPLOY_OPTION"
      exit 1
  esac
}

: <<'DOC'
  Parses CLI flags.
  See USAGE for flag descriptions.
DOC
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--debug)
        FLAG_RELEASE=false
        ;;
      -r|--release)
        FLAG_RELEASE=true
        ;;
      -p|--project)
        ENUM_DEPLOY_OPTION="project"
        ;;
      -s|--system)
        ENUM_DEPLOY_OPTION="system"
        ;;
      -R|--rust-only)
        FLAG_GO=false
        ;;
      -G|--go-only)
        FLAG_RUST=false
        ;;
      -b|--bundle)
        ENUM_DEPLOY_OPTION="bundle"
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
