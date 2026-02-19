#!/usr/bin/env bash
eval "${CI_ENVRC:-}"

__compile_api__GO_OUTPUT_PATH="$REPO_ROOT/dist/kaitos"
__compile_api__RUST_TARGET_DIR="$REPO_ROOT/crates/target"
__compile_api__RUST_OUTPUT_DIR="$REPO_ROOT/dist/lib"
__compile_api__RUST_MANIFEST_PATH="$REPO_ROOT/crates/Cargo.toml"

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
      The path to the output binary. Default is $REPO_ROOT/dist/kaitos.

  Returns:
    - 0 if the go binary is compiled successfully.
    - 1 if the go binary is not compiled successfully.
DOC
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
    args+=("-gcflags" "all=-N -l")
  fi

  output_path="${__opts__[output_path]:-$__compile_api__GO_OUTPUT_PATH}"

  cd "$REPO_ROOT/go" || return 1
  go build -o "$output_path" "${args[@]}" "./cmd/kaitos.go"
  cd "$REPO_ROOT" || return 1
}

: <<'DOC'
  Compiles the rust binary for the project.
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
      The path to the output directory. Default is $REPO_ROOT/dist/lib.
    options[manifest_path]: string
      The path to the cargo manifest. Default is $REPO_ROOT/crates/Cargo.toml.
    options[target_dir]: string
      The path to the target directory. Default is $REPO_ROOT/crates/target.
DOC
function compile_rust() {
  local -n __opts__="$1"
  local context args target_dir output_dir target_lib_dir

  context="debug"
  if [[ ${__opts__[release]} = true ]]; then
    context="release"
  fi

  output_dir="${__opts__[output_dir]:-$__compile_api__RUST_OUTPUT_DIR}"
  target_lib_dir="$context"

  args=()
  args+=("--manifest-path" "${__opts__[manifest_path]:-$__compile_api__RUST_MANIFEST_PATH}")

  target_dir="${__opts__[target_dir]:-$__compile_api__RUST_TARGET_DIR}"
  args+=("--target-dir" "$target_dir")
  if [[ "$context" = release ]]; then
    args+=("--release")
  fi

  cargo build --package godot "${args[@]}"

  mkdir -p "$output_dir"
  cp "$target_dir/$target_lib_dir/libgodot.so" "$output_dir/libgodot.so"
}