#!/usr/bin/env bash

: <<'DOC'
  Gets the latest pre-release version tag from git (has a - suffix).
  Matches tags like v1.0.0-alpha, v1.0.0-rc1, v0.5.0-beta.1
  Returns empty string if no pre-release tags exist.
DOC
function latest_prerelease_version() {
  git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+-' | head -1
}