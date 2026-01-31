#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Creates a GitHub release for the latest tag marked in the project manifest (kaitos.json)

Usage: cicd_create_release.sh [-h,--help]

Flags:
  -h, --help      Show this help text.

EOF
)"

import \
  "$REPO_ROOT/scripts/shared/manifest.api.sh" \
  "$REPO_ROOT/scripts/shared/get_date.func.sh" \
  "$REPO_ROOT/scripts/shared/git/get_version_type.func.sh"

function main() {
  parse_args "$@"

  local tag title notes version_type prerelease_flag

  tag="v$(manifest_get latest)"
  version_type="$(get_version_type "$tag")"

  if [[ "$version_type" == "release" ]]; then
    prerelease_flag=""
  else
    prerelease_flag="--prerelease"
  fi

  title="$(get_title "$tag" "$version_type")"
  notes="$(get_notes "$tag")"

  log "Creating release for $tag"
  log "  Type: $version_type"
  log "  Title: $title"

  # shellcheck disable=SC2086
  gh release create "$tag" \
    --title "$title" \
    --notes "$notes" \
    $prerelease_flag
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
  Generates the release title.
  For full releases: "Series: vX.Y.Z - Nickname"
  For prereleases:   "Series: vX.Y.Z-pre.N"
DOC
function get_title() {
  local tag="$1"
  local version_type="$2"
  local series nickname

  series="$(manifest_get series)"
  nickname="$(manifest_get release-nickname)"

  if [[ "$version_type" == "release" ]]; then
    echo "$series: $tag - $nickname"
  else
    echo "$series: $tag"
  fi
}

: <<'DOC'
  Generates the release notes using GitHub's API.
DOC
function get_notes() {
  local tag="$1"
  local org repo formatted_date notes

  org="$(manifest_get org)"
  repo="$(manifest_get repo)"
  formatted_date="$(get_formatted_date)"

  notes=$(gh api \
    "repos/$org/$repo/releases/generate-notes" \
    -f tag_name="$tag" \
    --jq ".body")

  echo "Released on $formatted_date"
  echo ""
  echo "$notes"
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

main "$@"
