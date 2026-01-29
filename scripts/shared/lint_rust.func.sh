#!/usr/bin/env bash

: <<'DOC'
  Checks Rust files for formatting issues using rustfmt.
  
  Usage: lint_rust
  
  Checks all Rust files in the crates workspace.
  Returns 0 if all files are formatted, 1 otherwise.
DOC
function lint_rust() {
  local repo_root

  repo_root="$(git rev-parse --show-toplevel)"

  if ! cargo fmt --manifest-path "$repo_root/crates/Cargo.toml" -- --check; then
    echo ""
    echo "Run 'cargo fmt --manifest-path crates/Cargo.toml' to fix."
    return 1
  fi

  return 0
}
