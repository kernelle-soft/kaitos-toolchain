#!/usr/bin/env bash

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