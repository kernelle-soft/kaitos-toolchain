#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Updates site/public/release-index.json with the latest release tag and
checksum, commits the change, and triggers a site deployment.

Usage: update_release_index.sh [-h,--help] <artifact>

Arguments:
  artifact        The release tarball to compute the checksum from.

Flags:
  -h, --help      Show this help text.

EOF
)"

ARG_ARTIFACT=""

import \
  "$KAITOSHOME/scripts/shared/manifest.api.sh" \
  "$KAITOSHOME/scripts/shared/versions.api.sh"

function main() {
  parse_args "$@"

  local tag channel checksum

  tag="v$(manifest_get latest)"
  channel="$(resolve_channel "$tag")"
  checksum="$(sha256sum "$ARG_ARTIFACT" | awk '{print $1}')"

  log "Updating release index: ${channel} → ${tag}"

  write_release_index "$tag" "$channel" "$checksum"
  commit_release_index "$tag"
  deploy_site
}

: <<'DOC'
  Returns "prerelease" or "stable" based on the tag's semver metadata.
DOC
function resolve_channel() {
  local -A parsed_version
  parse_version "$1" parsed_version

  if [[ -n "${parsed_version[pre_type]}" ]]; then
    echo "prerelease"
  else
    echo "stable"
  fi
}

: <<'DOC'
  Writes the tag and checksum into site/public/release-index.json for the
  given channel. Keys follow the flat naming convention:
    <channel>                     → tag
    <channel>_sha256_<os>_<arch>  → checksum
DOC
function write_release_index() {
  local tag="$1" channel="$2" checksum="$3"
  local checksum_key="${channel}_sha256_linux_x86_64"
  local index="$KAITOSHOME/site/public/release-index.json"

  local tmp
  tmp="$(mktemp)"

  jq --arg channel "$channel" \
     --arg tag "$tag" \
     --arg key "$checksum_key" \
     --arg checksum "$checksum" \
     '.[$channel] = $tag | .[$key] = $checksum' \
     "$index" > "$tmp"

  mv "$tmp" "$index"
}

: <<'DOC'
  Commits and pushes the updated release index.
  Uses [skip ci] to avoid retriggering the publish pipeline.
DOC
function commit_release_index() {
  local tag="$1"

  git add "$KAITOSHOME/site/public/release-index.json"

  if nothing_to_release; then
    log "Release index already up to date for ${tag}; skipping commit."
    return 0
  fi

  git commit -m "chore: update release index for ${tag} [skip ci]"
  git push
}

: <<'DOC'
  Checks if there are changes to be released.
  Returns 1 if there are, 0 if there are not.
DOC
function nothing_to_release() {
  git diff --cached --quiet
}

: <<'DOC'
  Triggers the docs workflow to deploy the site with the updated index.
  This manual trigger is needed because GITHUB_TOKEN pushes don't trigger other workflows.
DOC
function deploy_site() {
  log "Triggering site deployment..."
  gh workflow run docs.yaml
}

: <<'DOC'
  Parses CLI flags.
  See USAGE for flag descriptions.
DOC
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)  log "$USAGE" && exit 0;;
      -*)
        log "Unknown option: $1"
        log "$USAGE"
        exit 1
        ;;
      *)
        if [[ -z "$ARG_ARTIFACT" ]]; then
          ARG_ARTIFACT="$1"
        else
          log "Unexpected argument: $1"
          log "$USAGE"
          exit 1
        fi
        ;;
    esac
    shift
  done

  if [[ -z "$ARG_ARTIFACT" ]]; then
    log "Missing required argument: artifact"
    log "$USAGE"
    exit 1
  fi
}

main "$@"
