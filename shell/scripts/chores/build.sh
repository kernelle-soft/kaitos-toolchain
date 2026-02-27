#!/usr/bin/env bash
set -euo pipefail
eval "${SHELLSHOCK_ENVRC:-}"

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
      kaitos                          CLI binary
      lib/libgodot.{so,dylib}         Shared library
      shell/.shock/lib/               Shellshock libraries
      shell/scripts/lib/              Kaitos shell libraries
      shell/scripts/install/          Installer specific code
      templates/                      Config and env templates
      .envrc                          Environment bootstrap
      manifest.json                   Project metadata

  -h, --help
    Show this help text
EOF
)"

import \
  "$PROJ/shell/scripts/lib/compile.api.sh" \
  "$PROJ/shell/scripts/lib/deploy.api.sh"

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

  mkdir -p "$PROJ/dist"

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
      assemble_dist
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
  Copies installer scripts, templates, and metadata into dist/ so the
  release tarball is self-contained.

  The compiled artifacts (kaitos binary, lib/) are already in dist/
  from the compile phase. This adds everything else the installer needs.
DOC
function assemble_dist() {
  local dist="$PROJ/dist"

  rm -rf \
    "$dist/shell" \
    "$dist/templates" \
    "$dist/.envrc" \
    "$dist/manifest.json"

  mkdir -p "$dist/shell/.shock" "$dist/shell/scripts"
  cp -r "$PROJ/shell/.shock/lib"     "$dist/shell/.shock/lib"
  cp -r "$PROJ/shell/scripts/lib"    "$dist/shell/scripts/lib"
  cp -r "$PROJ/shell/scripts/install" "$dist/shell/scripts/install"
  cp -r "$PROJ/templates"         "$dist/templates"
  cp    "$PROJ/.envrc"            "$dist/.envrc"
  cp    "$PROJ/manifest.json"     "$dist/manifest.json"
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
