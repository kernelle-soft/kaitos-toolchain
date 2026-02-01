#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF

Flags:
  -h, --help        Show this help text.

EOF
)"

function main() {
  parse_args "$@"

  
}

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

main "$@"