#!/usr/bin/env bash
eval "${SHELLSHOCK_ENVRC:-}"

import "$PROJ/scripts/shared/cross_platform.api.sh"

__compile_api__GO_OUTPUT_PATH="$PROJ/dist/kaitos"
__compile_api__RUST_TARGET_DIR="$PROJ/crates/target"
__compile_api__RUST_OUTPUT_DIR="$PROJ/dist/lib"
__compile_api__RUST_MANIFEST_PATH="$PROJ/crates/Cargo.toml"

: <<'DOC'
  Compiles the go binary for the project.

  Usage:
    declare -A options
    options=(
      ...options...
    )
    compile_go options

  Options:
    options[release]: boolean
      Compile the go binary in release mode. Default is false.

    options[output_path]: string
      The path to the output binary. Default is $PROJ/dist/kaitos.

  Returns:
    - 0 if the go binary is compiled successfully.
    - 1 if the go binary is not compiled successfully.
DOC
function compile_go() {
  local build_context output_path args
  if [[ -z "${1:-}" ]]; then
    local -A __opts__=()
  else
    # The branch above allows invocation with or without args,
    # so the difference in local var declaration is intentional.
    # shellcheck disable=2178
    local -n __opts__="$1"
  fi

  build_context="debug"
  if [[ "${__opts__[release]:-}" = true ]]; then
    build_context="release"
  fi

  args=()
  if [[ "$build_context" = debug ]]; then
    args+=("-race")
    args+=("-gcflags" "all=-N -l")
  fi

  output_path="${__opts__[output_path]:-$__compile_api__GO_OUTPUT_PATH}"
  mkdir -p "$(dirname "$output_path")" || return 1

  cd "$PROJ/go" || return 1
  go build -o "$output_path" "${args[@]}" "./cmd/kaitos.go"
  cd "$PROJ" || return 1
}

: <<'DOC'
  Compiles the rust shared library (cdylib) for the project.

  Usage:
    declare -A options
    options=(
      ...options...
    )
    compile_rust options

  Options:
    options[release]: boolean
      Compile the rust binary in release mode. Default is false.
    options[output_dir]: string
      The path to the output directory. Default is $PROJ/dist/lib.
    options[manifest_path]: string
      The path to the cargo manifest. Default is $PROJ/crates/Cargo.toml.
    options[target_dir]: string
      The path to the target directory. Default is $PROJ/crates/target.

  Returns:
    - 0 if the shared library is compiled and copied successfully.
    - non-zero if an error occurs during compilation or copying.
DOC
function compile_rust() {
  local build_context args target_dir output_dir target_lib_dir
  if [[ -z "${1:-}" ]]; then
    local -A __opts__=()
  else
    # The branch above allows invocation with or without args,
    # so the difference in local var declaration is intentional.
    # shellcheck disable=2178
    local -n __opts__="$1"
  fi

  build_context="debug"
  if [[ "${__opts__[release]:-}" = true ]]; then
    build_context="release"
  fi

  output_dir="${__opts__[output_dir]:-$__compile_api__RUST_OUTPUT_DIR}"
  target_lib_dir="$build_context"

  args=()
  args+=("--manifest-path" "${__opts__[manifest_path]:-$__compile_api__RUST_MANIFEST_PATH}")

  target_dir="${__opts__[target_dir]:-$__compile_api__RUST_TARGET_DIR}"
  args+=("--target-dir" "$target_dir")
  if [[ "$build_context" = release ]]; then
    args+=("--release")
  fi

  cargo build --package godot "${args[@]}"

  local lib_file
  lib_file="$(shared_lib_filename godot)"

  mkdir -p "$output_dir"
  cp "$target_dir/$target_lib_dir/$lib_file" "$output_dir/$lib_file"
}
