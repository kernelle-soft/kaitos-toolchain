#!/usr/bin/env bash

: <<'DOC'
API for logging output to stderr.
DOC

function log() {
  echo "${1:-}" >&2
}

function warn() {
  echo "WARN: ${1:-}" >&2
}

function error() {
  echo "ERROR: ${1:-}" >&2
}

function fatal() {
  echo "FATAL: ${1:-}" >&2
}

function log_banner() {
  local msg="${1:-}"
  local min_width=40
  local msg_len="${#msg}"
  local padding=4  # space on each side of message

  # Expand width of banner if message is too long
  local banner_len=$((msg_len + padding * 2))
  if [[ "$banner_len" -lt "$min_width" ]]; then
    banner_len="$min_width"
  fi

  # Generate the dash line
  local banner_line
  banner_line="$(printf '%*s' "$banner_len" '' | tr ' ' '-')"

  # Center the message with padding
  local total_padding=$((banner_len - msg_len))
  local left_pad=$((total_padding / 2))
  local right_pad=$((total_padding - left_pad))
  local centered_msg
  centered_msg="$(printf '%*s%s%*s' "$left_pad" '' "$msg" "$right_pad" '')"

  # Print the banner
  echo "$banner_line" >&2
  echo "$centered_msg" >&2
  echo "$banner_line" >&2
}
