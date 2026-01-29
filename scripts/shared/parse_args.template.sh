#!/usr/bin/env bash
REPO_ROOT="$(git rev-parse --show-toplevel)"

source "$REPO_ROOT/scripts/shared/log.func.sh"

log <<EOF
ERROR: this file is just a template to avoid writing boilerplate.
EOF

: <<'DOC'
  Parses CLI flags. 
  See USAGE for flag descriptions.
DOC
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)  log "$USAGE" && exit 0;;
      *)
        log "Unknown option: $1"
        log "$USAGE"
        exit 1
        ;;
    esac
    shift
  done
}


