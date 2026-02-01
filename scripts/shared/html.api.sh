#!/usr/bin/env bash

__html_api__HTML_START="<!--HTML_START-->"

__html_api__depth=0

function html_start() {
  local id="$1"
  if [[ -n "$__html_api__depth" ]]; then
    log "WARNING: depth should be 0 before calling html_start(), but was $__html_api__depth"
    log "Resetting..."
  fi

  __html_api__depth=0
  echo "<!--HTML_START[$id]-->"
}

function html_end() {
  local id="$1"
  if [[ -n "$__html_api__depth" ]]; then
    log "WARNING: depth should be 0 before calling html_end(), but was $__html_api__depth"
    log "Resetting..."
  fi

  __html_api__depth=0
  echo "<!--HTML_END[$id]-->"
}

function table_start() {
  printf " %.0<table>" {0..$__html_api__depth}
  __html_api__push
}

function table_end() {
  __html_api__pop
  printf " %.0</table>" {0..$__html_api__depth}
}

function __html_api__push() {
  __html_api__depth=$((__html_api__depth + 1))
}

function __html_api__pop() {
  __html_api__depth=$((__html_api__depth - 1))
}