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
  local __ver__="$1"
  local -n __result__=$2
  local major minor patch pre_type="" pre_inc=""

  if ! is_valid_semver "$__ver__"; then
    warn "'$__ver__' is not a valid semver version for this project"
    return 1
  fi

  major="${__ver__%%.*}"; __ver__="${__ver__#*.}"
  minor="${__ver__%%.*}"; __ver__="${__ver__#*.}"
  patch="${__ver__%%-*}"

  if [[ "$__ver__" == *-* ]]; then
    local pre="${__ver__#*-}"
    pre_type="${pre%%.*}"
    pre_inc="${pre##*.}"
  fi

  __result__[major]="$major"
  __result__[minor]="$minor"
  __result__[patch]="$patch"
  __result__[pre_type]="$pre_type"
  __result__[pre_inc]="$pre_inc"
}

# ============================================================================
# Validation
# ============================================================================

: <<'DOC'
Checks whether the provided string is valid project semver
DOC
function is_valid_semver() {
  local version="$1"
  local regex_semver='^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z]+(\.[0-9]+)?)?$'
  local regex_semver_git_tag="^v${regex_semver#^}"  # ^v[0-9]+...

  [[
    "$version" =~ $regex_semver ||
    "$version" =~ $regex_semver_git_tag
  ]]
}

: <<'DOC'
Checks whether or not the semver version passed is a release version

Example:
- 1.0.0 -> true
- 0.4.2 -> true
- 12.20.0-alpha.1 -> false
- 1.0.0-rc.20 -> false
DOC
function is_release_version() {
  local -A version
  parse_version "$1" version
  [[ -z "${version[pre_type]}" ]]
}

: <<'DOC'
Gets the type of release this version represents

Example:
- 1.0.0 -> major
- 1.4.0 -> minor
- 1.4.2 -> patch
- 1.4.3-dev.1 -> dev
- 1.4.3-alpha.1 -> alpha
- etc
DOC
function get_release_type() {
  local -A ver
  parse_version "$1" ver

  if [[ -n "${ver[pre_type]}" ]]; then
    echo "${ver[pre_type]}"
    return
  fi

  if ((ver[patch] > 0)); then
    echo "patch"
  elif ((ver[minor] > 0)); then
    echo "minor"
  else
    echo "major"
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
  Returns the version without the 'v' prefix, or empty string if no pre-release tags exist.
DOC
function latest_prerelease_version() {
  local latest_tag semver

  latest_tag="$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+-' | head -1)"

  # Strip leading 'v' if there is one
  semver="${latest_tag#v}"
  echo "$semver"
}

: <<'DOC'
  Gets the latest v0.x.x release version tag from git (genesis/unfinished).
  Matches tags like v0.0.1, v0.5.0 but not v0.1.0-alpha.
  Returns the version without the 'v' prefix, or empty string if no v0.x.x release tags exist.
DOC
function latest_zero_version() {
  local latest_tag semver

  latest_tag="$(git tag --sort=-v:refname | grep -E '^v0\.[0-9]+\.[0-9]+$' | head -1)"

  # Strip leading 'v' if there is one
  semver="${latest_tag#v}"
  echo "$semver"
}
