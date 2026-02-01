#!/usr/bin/env bash
eval "${CI_ENVRC:-}"

: <<'DOC'
API for working with semver versions and git tags.
DOC

: <<'DOC'
Maps prerelease indicators to their relative importance. Higher number means
higher precedence.
DOC
declare -A __versions_api__precedence=(
  [dev]=0
  [alpha]=1
  [beta]=2
  [rc]=3
)

# ============================================================================
# Parsing
# ============================================================================

: <<'DOC'
  Parses a semver string into its components using a nameref to an associative array.

  Usage:
    local -A version
    parse_version "1.2.3-alpha.4" version

    echo "${version[major]}"      # 1
    echo "${version[minor]}"      # 2
    echo "${version[patch]}"      # 3
    echo "${version[pre_type]}"   # alpha
    echo "${version[pre_inc]}"    # 4
DOC
function parse_version() {
  local ver="$1"
  local -n _result=$2
  local major minor patch pre_type="" pre_inc=""

  major="${ver%%.*}"; ver="${ver#*.}"
  minor="${ver%%.*}"; ver="${ver#*.}"
  patch="${ver%%-*}"

  if [[ "$ver" == *-* ]]; then
    local pre="${ver#*-}"
    pre_type="${pre%%.*}"
    pre_inc="${pre##*.}"
  fi

  _result=(
    [major]="$major"
    [minor]="$minor"
    [patch]="$patch"
    [pre_type]="$pre_type"
    [pre_inc]="$pre_inc"
  )
}

# ============================================================================
# Validation
# ============================================================================

function is_valid_semver() {
  local version="$1"
  local regex_semver='^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z]+(\.[0-9]+)?)?$'
  local regex_semver_git_tag="^v${regex_semver#^}"  # ^v[0-9]+...

  [[
    "$version" =~ $regex_semver || 
    "$version" =~ $regex_semver_git_tag
  ]]
}

function get_version_type() {
  local version="$1"
  if [[ $version =~ ^v?0\. ]]; then
    echo "zero"
  elif [[ $version =~ - ]]; then
    echo "prerelease"
  else
    echo "release"
  fi
}

# ============================================================================
# Comparison
# ============================================================================

: <<'DOC'
  Compares two semver strings. This also accounts for prerelease precedence and increments:
    - dev.1 < dev.2
    - dev.2 < alpha.2 < beta.2 < rc.1
  
  Returns: -1 if left > right, 1 if left < right, 0 if equal.
DOC
function compare_versions() {
  local -A left right
  local result

  if [[ -z "$1" && -n "$2" ]]; then
    echo 1
    return
  elif [[ -n "$1" && -z "$2" ]]; then
    echo -1
    return
  elif [[ -z "$1" && -z "$2" ]]; then
    echo 0
    return
  fi

  parse_version "$1" left
  parse_version "$2" right

  # Compare major.minor.patch
  # Major
  result="$(__versions_api__compare_components "${left[major]}" "${right[major]}")"
  if [[ "$result" -ne 0 ]]; then
    echo "$result"
    return
  fi

  # Minor
  result="$(__versions_api__compare_components "${left[minor]}" "${right[minor]}")"
  if [[ "$result" -ne 0 ]]; then
    echo "$result"
    return
  fi

  # Patch
  result="$(__versions_api__compare_components "${left[patch]}" "${right[patch]}")"
  if [[ "$result" -ne 0 ]]; then
    echo "$result"
    return
  fi

  # Compare pre-release (release > prerelease)
  __versions_api__compare_prerelease left right
}

function __versions_api__compare_components() {
  local left="$1" right="$2"

  if (( left > right )); then
    echo -1
  elif (( left < right )); then
    echo 1
  else
    echo 0
  fi  
}

function __versions_api__compare_prerelease_type() {
  local left_type="$1" right_type="$2"

  # Release (empty pre_type) > prerelease
  if [[ -z "$left_type" && -n "$right_type" ]]; then
    echo -1
  elif [[ -n "$left_type" && -z "$right_type" ]]; then
    echo 1
  elif [[ -z "$left_type" && -z "$right_type" ]]; then
    echo 0
  else
    # Compare by precedence
    local left_prec="${__versions_api__precedence[$left_type]:-0}"
    local right_prec="${__versions_api__precedence[$right_type]:-0}"
    __versions_api__compare_components "$left_prec" "$right_prec"
  fi
}

function __versions_api__compare_prerelease() {
  local -n _left="$1" _right="$2"
  local result

  result="$(__versions_api__compare_prerelease_type "${_left[pre_type]}" "${_right[pre_type]}")"
  if [[ "$result" -ne 0 ]]; then
    echo "$result"
    return
  fi

  # Same type, compare increment
  __versions_api__compare_components "${_left[pre_inc]}" "${_right[pre_inc]}"
}

# ============================================================================
# Git Tag Queries
# ============================================================================

: <<'DOC'
  Gets the latest tagged version from git. This can be either a pre-release or full release.

  If there is no previous tag, this returns "0.0.0". Otherwise, it will get the current tag
  with the leading 'v' stripped.
DOC
function latest_version() {
  local latest_tag semver

  latest_tag="$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")"

  # Strip leading 'v' if there is one
  semver="${latest_tag#v}"
  echo "$semver"
}

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

: <<'DOC'
  Gets the latest pre-release version tag from git (has a - suffix).
  Matches tags like v1.0.0-alpha, v1.0.0-rc1, v0.5.0-beta.1
  Returns empty string if no pre-release tags exist.
DOC
function latest_prerelease_version() {
  git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+-' | head -1
}

: <<'DOC'
  Gets the latest v0.x.x release version tag from git (genesis/unfinished).
  Matches tags like v0.0.1, v0.5.0 but not v0.1.0-alpha.
  Returns empty string if no v0.x.x release tags exist.
DOC
function latest_zero_version() {
  git tag --sort=-v:refname | grep -E '^v0\.[0-9]+\.[0-9]+$' | head -1
}
