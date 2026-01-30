#!/usr/bin/env bash

__compare_versions_repo_root="$(git rev-parse --show-toplevel)"
source "$__compare_versions_repo_root/scripts/shared/git/parse_version.func.sh"

declare -A __compare_versions_precedence=(
  [dev]=0
  [alpha]=1
  [beta]=2
  [rc]=3
)

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
  result="$(__compare_versions_components "${left[major]}" "${right[major]}")"    
  if [[ "$result" -ne 0 ]]; then
    echo "$result"
    return
  fi

  # Minor
  result="$(__compare_versions_components "${left[minor]}" "${right[minor]}")"
  if [[ "$result" -ne 0 ]]; then
    echo "$result"
    return
  fi

  # Patch
  result="$(__compare_versions_components "${left[patch]}" "${right[patch]}")"
  if [[ "$result" -ne 0 ]]; then
    echo "$result"
    return
  fi

  # Compare pre-release (release > prerelease)
  __compare_versions_prerelease left right
}

function __compare_versions_components() {
  local left="$1" right="$2"

  if (( left > right )); then
    echo -1
  elif (( left < right )); then
    echo 1
  else
    echo 0
  fi  
}

function __compare_versions_prerelease_type() {
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
    local left_prec="${__compare_versions_precedence[$left_type]:-0}"
    local right_prec="${__compare_versions_precedence[$right_type]:-0}"
    __compare_versions_components "$left_prec" "$right_prec"
  fi
}

function __compare_versions_prerelease() {
  local -n _left="$1" _right="$2"
  local result

  result="$(__compare_versions_prerelease_type "${_left[pre_type]}" "${_right[pre_type]}")"
  if [[ "$result" -ne 0 ]]; then
    echo "$result"
    return
  fi

  # Same type, compare increment
  __compare_versions_components "${_left[pre_inc]}" "${_right[pre_inc]}"
}