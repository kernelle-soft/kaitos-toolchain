#!/usr/bin/env bash
eval "${CI_ENVRC:-}"

: <<'DOC'
API for getting and setting managed information in the project's environment settings
DOC

__envrc_api__file="$KAITOSHOME/.envrc"
__envrc_api__slug_begin="@managed:begin"
__envrc_api__slug_end="@managed:end"

declare -gA __envrc_api__cache
declare -gA __envrc_api__schema=(
  [godot_url]="GODOT_URL"
  [godot_version]="GODOT_VERSION"
)

: <<'DOC'
  Gets a particular variable from the project environment

  Usage: envrc_get <key>
DOC
function envrc_get() {
  local key var managed_section

  key="$1"
  var="${__envrc_api__schema["$key"]}"

  if [[ -z "$var" ]]; then
    warn "Unknown project environment key: '$key'"
    return 1
  fi

  if [[ -z "${__envrc_api__cache["$var"]+isset}" ]]; then
    local -A managed_section

    __envrc_api__load_variables managed_section
    __envrc_api__cache["$var"]="${managed_section["$var"]}"
  fi

  echo "${__envrc_api__cache["$var"]}"
}

: <<'DOC'
  Sets a variable in the project environment.

  Usage: envrc_set <key> <value>
DOC
function envrc_set() {
  local key="$1"
  local value="$2"
  local var="${__envrc_api__schema["$key"]}"
  local -A variables

  if [[ -z "$var" ]]; then
    warn "Unknown project environment key '$key'"
    return 1
  fi

  __envrc_api__load_variables variables
  # shellcheck disable=SC2034
  variables["$var"]="$value"
  __envrc_api__save_variables variables

  __envrc_api__cache["$var"]="$value"
}

function __envrc_api__get_managed_section() {
  local section

  # Read in managed section.
  section="$(cat "$__envrc_api__file")"
  section="${section#*$__envrc_api__slug_begin}"
  section="${section%%$__envrc_api__slug_end*}"

  echo "$section"
}

function __envrc_api__load_variables() {
  local section
  local -n __variables__="$1"

  # Read in managed section.
  section="$(__envrc_api__get_managed_section)"

  # Parse into namespaced associative array.
  __variables__=()

  for key in "${!__envrc_api__schema[@]}"; do
    local line var
    var="${__envrc_api__schema["$key"]}"
    __variables__["$var"]=""

    # skip if there's no variable set
    line="$(echo "$section" | grep "$var=")"
    [[ -z "$line" ]] && continue

    # pull out value set in environment variable.
    __variables__["$var"]="${line#*=}"
    __variables__["$var"]="${__variables__["$var"]//\"/}"
  done
}

function __envrc_api__save_variables() {
  local -n __variables__="$1"
  local tmp range
  tmp="$(mktemp)"
  range="/^# ${__envrc_api__slug_begin}/,/^# ${__envrc_api__slug_end}/"
  cp "$__envrc_api__file" "$tmp"

  # Replace variable declarations and prepend new declarations.
  # We do this line-by-line since `sed` does not handle
  # newlines gracefully. We use `sed` despite this weakness
  # to avoid relying on multiple string editing tools across
  # the project.
  for var in "${!__variables__[@]}"; do
    local val="${__variables__[$var]}"

    if __envrc_api__exists_in_managed_block "$tmp" "^${var}="; then
      local old_line new_line
      old_line="^${var}=.*"
      new_line="${var}=\"${val}\""

      sed -i "${range}s|$old_line|$new_line|" "$tmp"
    else
      sed -i "/^# ${__envrc_api__slug_end}/i ${var}=\"${val}\"" "$tmp"
    fi
  done

  mv "$tmp" "$__envrc_api__file"
}

function __envrc_api__exists_in_managed_block() {
  local file="$1"
  local pattern="$2"
  local range="/^# ${__envrc_api__slug_begin}/,/^# ${__envrc_api__slug_end}/p"

  sed -n "$range" "$file" | grep -q "$pattern"
}
