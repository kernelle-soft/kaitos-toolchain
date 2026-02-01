#!/usr/bin/env bash

: <<'DOC'
API for linting and formatting checks.
DOC

: <<'DOC'
  Checks Go files for formatting issues using gofmt.
  
  Usage: lint_go [files...]
  
  If no files are provided, checks all Go files under go/.
  Returns 0 if all files are formatted, 1 otherwise.
DOC
function lint_go() {
  local repo_root files unformatted

  repo_root="$(git rev-parse --show-toplevel)"

  if [[ $# -gt 0 ]]; then
    files=("$@")
  else
    files=("$repo_root/go/")
  fi

  unformatted="$(gofmt -l "${files[@]}" 2>/dev/null || true)"

  if [[ -n "$unformatted" ]]; then
    echo "The following Go files need formatting:"
    echo "$unformatted"
    echo ""
    echo "Run 'gofmt -w go/' to fix."
    return 1
  fi

  return 0
}

: <<'DOC'
  Checks Rust files for formatting issues using rustfmt.
  
  Usage: lint_rust
  
  Checks all Rust files in the crates workspace.
  Returns 0 if all files are formatted, 1 otherwise.
DOC
function lint_rust() {
  local repo_root

  repo_root="$(git rev-parse --show-toplevel)"

  if ! cargo fmt --manifest-path "$repo_root/crates/Cargo.toml" --all -- --check; then
    echo ""
    echo "Run 'cargo fmt --manifest-path crates/Cargo.toml --all' to fix."
    return 1
  fi

  return 0
}
