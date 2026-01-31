#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF

Flags:
  -p, --prerelease    Use pre-release formatting
  -h, --help          Show this help text.

EOF
)"

import "$REPO_ROOT/scripts/shared/manifest.api.sh"

FLAG_PRERELEASE=false

function main() {
  parse_args "$@"
  local tag series nickname

  tag="v$(manifest_get latest)"
  series="$(manifest_get series)"
  nickname="$(manifest_get release-nickname)"

  if [[ $FLAG_PRERELEASE = true ]]; then
    echo "$series: $tag"
  else
    echo "$series: $tag - $nickname"
  fi
}

: <<'DOC'
  Parses CLI flags. 
  See USAGE for flag descriptions.
DOC
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--prerelease)  FLAG_PRERELEASE=true;;
      -h|--help)        log "$USAGE" && exit 0;;
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