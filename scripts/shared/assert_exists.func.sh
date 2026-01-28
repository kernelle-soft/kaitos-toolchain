#!/usr/bin/env bash

function assert_exists() {
    local val="$1"
    local message="${2:-}"
    if [[ -z "$val" ]]; then
        if [[ -n "$message" ]]; then
            echo "$message" >&2
        else
            echo "ERROR: unset variable" >&2
        fi
        exit 1
    fi
}