#!/usr/bin/env bash

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
