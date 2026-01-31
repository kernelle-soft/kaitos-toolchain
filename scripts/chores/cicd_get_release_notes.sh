#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Creates release notes for the latest tag marked in the project manifest (kaitos.json)

Usage: cicd_get_release_notes.sh [-h,--help]

Flags:
  -h, --help      Show this help text.

EOF
)"

import \
  "$REPO_ROOT/scripts/shared/get_date.func.sh" \
  "$REPO_ROOT/scripts/shared/manifest.api.sh"

function main() {
  local formatted_date notes
  parse_args "$@"

  if ! formatted_date="$(get_formatted_date)"; then
    log "Error getting formatted date string"
    exit 1
  fi

  if ! notes="$(get_notes)"; then
    log "Error generating release notes"
    exit 1
  fi

  echo "Released on $formatted_date"
  echo ""
  echo "$notes"
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

: <<'DOC'
  Formats the date string in the format of 
  "Month Day, Year Hour:Minute AM/PM Timezone"
DOC
function get_formatted_date() {
  local -A _date
  local y mon d suf h min ampm tz

  get_date _date

  y="${_date[year]}"
  mon="${_date[month]}"
  d="${_date[day]}"
  h="${_date[hours_12]}"
  min="${_date[minutes]}"
  ampm="${_date[ampm]}"
  suf="${_date[day_suffix]}"
  tz="${_date[timezone]}"

  echo "$mon $d$suf, $y $h:$min $ampm $tz"
}

: <<'DOC'
  Gets the release notes for the latest tag, including prerelease notes.
DOC
function get_notes() {
  local org repo tag notes

  if ! org="$(manifest_get org)"; then
    return 1
  fi

  if ! repo="$(manifest_get repo)"; then
    return 1
  fi

  if ! tag="v$(manifest_get latest)"; then
    return 1
  fi

  if ! notes=$(gh api \
    "repos/$org/$repo/releases/generate-notes" \
    -f tag_name="$tag" \
    --jq ".body"); then
    return 1
  fi

  echo "$notes"
}

main "$@"