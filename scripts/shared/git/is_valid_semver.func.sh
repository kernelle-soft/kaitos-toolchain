#!/usr/bin/env bash

function is_valid_semver() {
  local version="$1"
  local regex_semver='^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z]+(\.[0-9]+)?)?$'
  local regex_semver_git_tag="^v${regex_semver#^}"  # ^v[0-9]+...

  [[
    "$version" =~ $regex_semver || 
    "$version" =~ $regex_semver_git_tag
  ]]
}
