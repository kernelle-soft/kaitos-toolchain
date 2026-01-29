#!/usr/bin/env bash

: <<'DOC'
  Gets the latest tagged version from git. This can be either a pre-release or full release.

  If there is no previous tag, this returns "0.0.0". Otherwise, it will get the current tag
  with the leading 'v' stripped.
DOC
function get_current_version() {
  local latest_tag semver

  latest_tag="$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")"

  # Strip leading 'v' if there is one
  semver="${latest_tag#v}"
  echo "$semver"
}