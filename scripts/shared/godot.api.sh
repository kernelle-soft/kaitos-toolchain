#!/usr/bin/env bash

__godot_api__VERSIONS_URL="https://api.github.com/repos/godotengine/godot/tags"

function list_engine_versions() {
  local results filtered versions

  results="$(curl -s "$__godot_api__VERSIONS_URL")"
  filtered="$(grep -oP '"name": "\K[^"]+' <<< $results)"

  # strip out "-stable" from tags.
  versions="${filtered//-stable/}"

  echo "$versions"
}

function is_valid_godot_version() {
  local version valid_versions

  version="$1"
  valid_versions="$(list_engine_versions)"

  [[ "$valid_versions" == *"$version"* ]]
}
