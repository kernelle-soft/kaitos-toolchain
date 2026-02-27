#!/usr/bin/env bash
set -euo pipefail

USAGE="$(cat <<EOF
Polls the release index until it reflects the expected tag.

Usage: await_release_index.sh [flags] <tag>

Arguments:
  tag             The release tag to wait for (e.g. v1.2.3-dev.4).

Flags:
  -t, --timeout   Max seconds to wait (default: 120).
  -i, --interval  Seconds between polls (default: 10).
  -c, --channel   Release channel to check (default: prerelease).
  -h, --help      Show this help text.

EOF
)"

RELEASE_INDEX_URL="https://kaitos.dev/release-index.json"

ARG_TAG=""
FLAG_TIMEOUT=120
FLAG_INTERVAL=2
FLAG_CHANNEL="prerelease"

function main() {
  parse_args "$@"

  local elapsed=0 tag=""
  echo "Waiting for release index to reflect ${ARG_TAG} (channel: ${FLAG_CHANNEL})..."

  while [ "$elapsed" -lt "$FLAG_TIMEOUT" ]; do
    tag="$(curl -fsSL "$RELEASE_INDEX_URL" | jq -r --arg ch "$FLAG_CHANNEL" '.[$ch] // empty')" || true

    if [ "$tag" = "$ARG_TAG" ]; then
      echo "Release index updated (${elapsed}s)"
      return 0
    fi

    echo "  index has '${tag}', waiting ${FLAG_INTERVAL}s... (${elapsed}/${FLAG_TIMEOUT}s)"
    sleep "$FLAG_INTERVAL"
    elapsed=$((elapsed + FLAG_INTERVAL))
  done

  echo "::warning::Release index did not update within ${FLAG_TIMEOUT}s (has '${tag}', expected '${ARG_TAG}')"
  return 1
}

function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--timeout)  shift; FLAG_TIMEOUT="$1" ;;
      -i|--interval) shift; FLAG_INTERVAL="$1" ;;
      -c|--channel)  shift; FLAG_CHANNEL="$1" ;;
      -h|--help)     echo "$USAGE"; exit 0 ;;
      -*)
        echo "Unknown option: $1" >&2
        echo "$USAGE" >&2
        exit 1
        ;;
      *)
        if [[ -z "$ARG_TAG" ]]; then
          ARG_TAG="$1"
        else
          echo "Unexpected argument: $1" >&2
          echo "$USAGE" >&2
          exit 1
        fi
        ;;
    esac
    shift
  done

  if [[ -z "$ARG_TAG" ]]; then
    echo "Missing required argument: tag" >&2
    echo "$USAGE" >&2
    exit 1
  fi
}

main "$@"
