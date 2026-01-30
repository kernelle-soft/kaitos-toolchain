#!/usr/bin/env bash

: <<'DOC'
API for getting and setting info in the project manifest (kaitos.json)
DOC

__manifest_api_repo_root="$(git rev-parse --show-toplevel)"
source "$__manifest_api_repo_root/scripts/shared/log.func.sh"

declare -A __manifest_api_schema=(
  [name]=".name"
  [latest]=".latest"
  [stable]=".stable"
  [releases]=".releases"
  [series]=".series"
  [release-nickname]='."release-nickname"'
)

declare -A __manifest_api_cache

__manifest_api_file="$__manifest_api_repo_root/kaitos.json"

: <<'DOC'
  Gets a particular key from the kaitos manifest.

  Usage: manifest_get <key>
DOC
function manifest_get() {
  local key="$1"
  local path="${__manifest_api_schema["$key"]}"

  if [[ -z "$path" ]]; then
    log "Unknown kaitos.json key: '$key'"
    return 1
  fi

  if [[ -z "${__manifest_api_cache[$path]+isset}" ]]; then
    __manifest_api_cache["$path"]=$(jq -r "$path" < "$__manifest_api_file")
  fi

  echo "${__manifest_api_cache[$path]}"
}

: <<'DOC'
  Sets a particular key in the kaitos manifest.

  Usage: manifest_set <key> <value>
DOC
function manifest_set() {
  local key="$1"
  local value="$2"
  local path="${__manifest_api_schema["$key"]}"

  if [[ -z "$path" ]]; then
    log "Unknown kaitos.json key: '$key'"
    return 1
  fi

  local temp_file
  temp_file="$(mktemp)"

  jq \
    --arg v "$value" \
    "$path = (\$v | tonumber? // \$v)" \
    "$__manifest_api_file" > "$temp_file"

  mv "$temp_file" "$__manifest_api_file"

  __manifest_api_cache["$path"]="$value"
}