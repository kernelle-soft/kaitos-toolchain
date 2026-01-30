#!/usr/bin/env bash

: <<'DOC'
  Gets the latest release version tag from git (no pre-release suffix).
  Matches tags like v1.0.0, v0.5.0 but not v1.0.0-alpha or v1.0.0-rc1.
  Returns the version without the 'v' prefix, or empty string if no release tags exist.
DOC
function latest_release_version() {
  local latest_tag semver

  latest_tag="$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1)"
  
  # Strip leading 'v' if there is one
  semver="${latest_tag#v}"
  echo "$semver"
}