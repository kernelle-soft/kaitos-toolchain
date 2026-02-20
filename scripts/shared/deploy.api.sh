#!/usr/bin/env bash
eval "${CI_ENVRC:-}"

__deploy_api__DEFAULT_SOURCE_DIR="$REPO_ROOT/dist"
__deploy_api__XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
__deploy_api__XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
__deploy_api__KAITOS_LIB_DIR="$__deploy_api__XDG_DATA_HOME/kaitos/lib"

: <<'DOC'
  Deploys artifacts from a source directory to XDG-compliant system locations.

  Usage:
    declare -A options
    options=(
      [source_dir]="/path/to/artifacts"
    )
    deploy_system options

  Options:
    options[source_dir]: string
      Path to the directory containing built artifacts.
      Default is $REPO_ROOT/dist.

  Expects source_dir to contain:
    - kaitos        (CLI binary)
    - lib/libgodot.so  (Rust cdylib)

  Deploys to:
    - $XDG_BIN_HOME/kaitos
    - $XDG_DATA_HOME/kaitos/lib/libgodot.so
DOC
function deploy_system() {
  local source_dir
  if [[ -z "${1:-}" ]]; then
    local -A __opts__=()
  else
    # The branch above allows invocation with or without args,
    # so the difference in local var declaration is intentional.
    # shellcheck disable=2178
    local -n __opts__="$1"
  fi

  source_dir="${__opts__[source_dir]:-$__deploy_api__DEFAULT_SOURCE_DIR}"

  mkdir -p "$__deploy_api__XDG_BIN_HOME"
  cp "$source_dir/kaitos" "$__deploy_api__XDG_BIN_HOME/kaitos"

  mkdir -p "$__deploy_api__KAITOS_LIB_DIR"
  cp "$source_dir/lib/libgodot.so" "$__deploy_api__KAITOS_LIB_DIR/libgodot.so"
}

: <<'DOC'
  No-op hook for local deployment. Artifacts are already in source_dir
  (i.e. dist/) after the compile phase, so there's nothing to move.

  Exists as a hook point for future extension (e.g. symlinking, logging).

  Usage:
    deploy_project
DOC
function deploy_project() {
  :
}

: <<'DOC'
  Creates a versioned tarball from a source directory.
  Requires manifest.api.sh to be sourced (uses manifest_get for versioning).

  Usage:
    declare -A options
    options=(
      [source_dir]="/path/to/artifacts"
    )
    deploy_bundle options

  Options:
    options[source_dir]: string
      Path to the directory containing built artifacts.
      Default is $REPO_ROOT/dist.

  Outputs:
    Prints the artifact name (without .tar.gz) to stdout for capture by CI.
    Tarball is created in the current working directory.

  Dependencies:
    Imports manifest.api.sh internally rather than at the module level.
    deploy_system and deploy_project are designed to work outside the repo
    (e.g. a curl|sh bootstrapper that only needs to place artifacts).
    Importing manifest.api.sh here keeps that dependency scoped to bundle,
    which is only used during builds where $REPO_ROOT is available.
DOC
function deploy_bundle() {
  import "$REPO_ROOT/scripts/shared/manifest.api.sh"

  local source_dir version os arch artifact_name
  if [[ -z "${1:-}" ]]; then
    local -A __opts__=()
  else
    # The branch above allows invocation with or without args,
    # so the difference in local var declaration is intentional.
    # shellcheck disable=2178
    local -n __opts__="$1"
  fi

  source_dir="${__opts__[source_dir]:-$__deploy_api__DEFAULT_SOURCE_DIR}"
  version="$(manifest_get latest)"
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  artifact_name="kaitos-${version}-${os}-${arch}"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  cp -r "$source_dir" "$tmp_dir/$artifact_name"
  tar -czvf "${artifact_name}.tar.gz" -C "$tmp_dir" "$artifact_name" >&2

  echo "$artifact_name"
}
