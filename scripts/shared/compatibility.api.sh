#!/usr/bin/env bash
eval "${CI_ENVRC:-}"

import "$KAITOSHOME/scripts/shared/manifest.api.sh"

: <<'DOC'
API for checking version compatibility against supported engine versions
declared in manifest.json.
DOC

: <<'DOC'
  Checks whether a given version is supported for a given engine.

  Usage: is_supported_engine_version <engine> <version>

  Returns 0 if supported, 1 otherwise.
DOC
function is_supported_engine_version() {
  local engine="$1"
  local version="$2"
  local supported

  supported="$(manifest_get "${engine}_supported")"

  [[ ",$supported," == *",$version,"* ]]
}
