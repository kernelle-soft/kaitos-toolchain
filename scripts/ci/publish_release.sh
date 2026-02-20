#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Creates a GitHub release for the latest tag marked in the project manifest

Usage: publish_release.sh [-h,--help] [artifact...]

Arguments:
  artifact        Optional artifact files to attach to the release.

Flags:
  -d, --dry-run   Puts together a dry run of a release for review
  -h, --help      Show this help text.

EOF
)"

ARG_ARTIFACTS=()
FLAG_DRY_RUN=false

import \
  "$KAITOSHOME/scripts/shared/manifest.api.sh" \
  "$KAITOSHOME/scripts/shared/versions.api.sh" \
  "$KAITOSHOME/scripts/shared/get_date.func.sh"

function main() {
  parse_args "$@"

  local tag title notes prerelease_flag
  local -A version

  tag="v$(manifest_get latest)"
  parse_version "$tag" version

  if [[ -n "${version[pre_type]}" ]]; then
    prerelease_flag="--prerelease"
  else
    prerelease_flag=""
  fi

  title="$(get_title "$tag")"
  notes="$(get_notes "$tag")"

  if [[ $FLAG_DRY_RUN = true ]]; then
    log "Dry-Run for Release $tag"
    log "  Title: $title"

    if [[ -n "$prerelease_flag" ]]; then
      log "  Type: Prerelease"
    else
      log "  Type: Release"
    fi

    log "Notes:"
    log "$notes"

    log "Artifacts:"
    log ${ARG_ARTIFACTS[@]+"${ARG_ARTIFACTS[@]}"}
    exit 0
  fi

  # Intentionally leaving out the quotes on $prerelease_flag.
  # Otherwise, "" will be passed explicitly if prerelease isn't set,
  # breaking the pipeline.
  gh release create "$tag" \
    --title "$title" \
    --notes "$notes" \
    $prerelease_flag \
    ${ARG_ARTIFACTS[@]+"${ARG_ARTIFACTS[@]}"}
}

: <<'DOC'
  Parses CLI flags.
  See USAGE for flag descriptions.
DOC
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--dry-run)   FLAG_DRY_RUN=true;;
      -h|--help)  log "$USAGE" && exit 0;;
      -*)
        log "Unknown option: $1"
        log "$USAGE"
        exit 1
        ;;
      *)
        ARG_ARTIFACTS+=("$1")
        ;;
    esac
    shift
  done
}

: <<'DOC'
  Generates the release title based on the context of development.
DOC
function get_title() {
  local tag major_name minor_name patch_name

  tag="$1"
  major_name="$(manifest_get major_name)"
  minor_name="$(manifest_get minor_name)"
  patch_name="$(manifest_get patch_name)"

  case "$(get_release_type "$tag")" in
    patch)
      echo "$tag: $patch_name - $minor_name"
      ;;
    minor)
      echo "$tag: $minor_name"
      ;;
    major)
      echo "$tag: $major_name"
      ;;
    *)
      echo "$tag"
      ;;
  esac
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
