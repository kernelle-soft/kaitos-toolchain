#!/usr/bin/env bash

function get_version_type() {
  local version="$1"
  if [[ $version =~ ^v0\. ]]; then
    echo "zero"
  elif [[ $version =~ - ]]; then
    echo "prerelease"
  else
    echo "release"
  fi
}