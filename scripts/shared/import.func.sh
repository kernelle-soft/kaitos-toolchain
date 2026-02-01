#!/usr/bin/env bash

function import() {
    for script in "$@"; do
        [[ -f "$script" ]] || { echo "import: not found: $script" >&2; return 1; }

        # shellcheck disable=SC1090
        source "$script"
    done
}