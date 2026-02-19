#!/usr/bin/env bash
eval "${CI_ENVRC:-}"

__compile_api__GO_OUTPUT_PATH="$REPO_ROOT/go/kaitos"
__compile_api__RUST_TARGET_DIR="$REPO_ROOT/crates/target"
__compile_api__RUST_MANIFEST_PATH="$REPO_ROOT/crates/Cargo.toml"

function compile_go() {
  local -n __opts__="$1"
  local context output_path args

  context="dev"
  if [[ ${__opts__[release]} = true ]]; then
    context="release"
  fi

  args=()
  if [[ "$context" = dev ]]; then
    args+=("-race")
  fi

  output_path="${__opts__[output_path]:-$__compile_api__GO_OUTPUT_PATH}"

  cd "$REPO_ROOT/go" || return 1
  go build -o "$output_path" "${args[@]}" "./cmd/kaitos.go"
  cd "$REPO_ROOT" || return 1
}

function compile_rust() {
  local -n __opts__="$1"
  local context args

  context="dev"
  if [[ ${__opts__[release]} = true ]]; then
    context="release"
  fi

  args=()
  args+=("--manifest-path" "${__opts__[manifest_path]:-$__compile_api__RUST_MANIFEST_PATH}")
  args+=("--target-dir" "${__opts__[target_dir]:-$__compile_api__RUST_TARGET_DIR}")
  if [[ "$context" = release ]]; then
    args+=("--release")
  fi

  cargo build --package godot "${args[@]}"
}