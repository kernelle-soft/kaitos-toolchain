#!/usr/bin/env bash

function is_valid_url() {
  local url="$1"
  curl --output /dev/null --silent --head --fail "$url"
}