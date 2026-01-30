#!/usr/bin/env bash


: <<'DOC'
API for getting and setting info in the project manifest
DOC
__file_scope__() {
  local __repo_root
  
  __repo_root="$(git rev-parse --show-toplevel)"
  source "$__repo_root/scripts/shared/log.func.sh"
  
  declare -A __manifest_schema=(
    [name]=".name"
    [latest]=".latest"
    [stable]=".stable"
    [releases]=".releases"
    [series]=".series"
    [release-nickname]=".release-nickname"
  )

  declare -A __cache

  local __manifest_file="$__repo_root/kaitos.json"


: <<'DOC'
  Gets a particular key from the kaitos manifest.

  Usage: manifest_get <key>
DOC
  function manifest_get() {
    local key="$1"
    local path="${__manifest_schema["$key"]}"

    if [[ -z "$path" ]]; then
      log "Unknown kaitos.json key: '$key'"
      return 1
    fi

    if [[ -z "${__cache[$path]+isset}" ]]; then
        __cache["$path"]=$(jq "$path" < "$__manifest_file")
    fi

    echo "${__cache[$path]}"
  }

: <<'DOC'
  Sets a particular key in the kaitos manifest.

  Usage: manifest_set <key> <value>
DOC
  function manifest_set() {
    local key="$1"
    local value="$2"
    local path="${__manifest_schema["$key"]}"

    mkdir -p "$__repo_root/temp"

    if [[ -z "$path" ]]; then
      log "Unknown kaitos.json key: '$key'"
      return 1
    fi

    jq \
      --arg v "$value" \
      "$path = (\$v | tonumber? // \$v)" \
      "$__manifest_file" > "$__repo_root/temp/kaitos.json"

    mv "$__repo_root/temp/kaitos.json" "$__manifest_file"

    rm -rf "$__repo_root/temp"

    __cache["$path"]="$value"
  }
}

__file_scope__
unset -f __file_scope__