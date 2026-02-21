#!/usr/bin/env bash
eval "${CI_ENVRC:-}"

: <<'DOC'
API for getting and setting info in the project manifest.
DOC

__manifest_api_file="$KAITOSHOME/manifest.json"

declare -gA __manifest_api_cache
declare -gA __manifest_api_schema=(
  [command_name]='."command-name"'
  [org]=".org"
  [repo]=".repo"
  [latest]=".latest"
  [stable]=".stable"
  [releases]=".releases"
  [major_name]='.naming.major'
  [minor_name]='.naming.minor'
  [patch_name]='.naming.patch'
  [godot_version]='.engines.godot.version'
  [godot_url]='.engines.godot.url'
  [godot_supported]='.engines.godot.supported | join(",")'
)

: <<'DOC'
  Gets a particular key from the kaitos manifest.

  Usage: manifest_get <key>
DOC
function manifest_get() {
  local key="$1"
  local path="${__manifest_api_schema["$key"]}"

  if [[ -z "$path" ]]; then
    log "Unknown manifest.json key: '$key'"
    return 1
  fi

  if [[ -z "${__manifest_api_cache[$path]+isset}" ]]; then
    local value
    if ! value=$(jq -r "$path" < "$__manifest_api_file"); then
      log "Failed to read manifest.json key '$key'"
      return 1

    elif [[ "$value" == "null" ]]; then
      log "manifest.json key '$key' is null or missing"
      return 1
    fi

    __manifest_api_cache["$path"]="$value"
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
    log "Unknown manifest.json key: '$key'"
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