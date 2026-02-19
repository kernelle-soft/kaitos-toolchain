#!/usr/bin/env bash
eval "${CI_ENVRC:-}"

function deploy_go() {
  local -n __opts__="$1"
  local target

  target="xdg"
  if [[ "${__opts__[local]}" = true ]]; then
    target="local"
  fi

  if [[]]
}


function deploy_rust() {
  local -n __opts__="$1"
  local target

  target="xdg"
  if [[ "${__opts__[local]}" = true ]]; then
    target="local"
  fi
}