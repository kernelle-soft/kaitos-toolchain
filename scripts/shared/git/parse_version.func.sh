#!/usr/bin/env bash

: <<'DOC'
  Parses a semver string into its components using namerefs.
  Usage: parse_version "1.2.3-alpha.4" major minor patch pre_type pre_inc
DOC
function parse_version() {
  local ver="$1"
  local -n _major=$2 _minor=$3 _patch=$4 _pre_type=$5 _pre_inc=$6

  _major="${ver%%.*}"; ver="${ver#*.}"
  _minor="${ver%%.*}"; ver="${ver#*.}"
  _patch="${ver%%-*}"
  _pre_type=""
  _pre_inc=""

  if [[ "$ver" == *-* ]]; then
    local pre="${ver#*-}"
    _pre_type="${pre%%.*}"
    _pre_inc="${pre##*.}"
  fi
}