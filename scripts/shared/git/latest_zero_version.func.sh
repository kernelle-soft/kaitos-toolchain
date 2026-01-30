#!/usr/bin/env bash

: <<'DOC'
  Gets the latest v0.x.x release version tag from git (genesis/unfinished).
  Matches tags like v0.0.1, v0.5.0 but not v0.1.0-alpha.
  Returns empty string if no v0.x.x release tags exist.
DOC
function latest_zero_version() {
  git tag --sort=-v:refname | grep -E '^v0\.[0-9]+\.[0-9]+$' | head -1
}