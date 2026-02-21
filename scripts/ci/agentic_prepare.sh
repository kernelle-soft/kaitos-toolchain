#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Fetches context needed by the triage prompt: issue details and label catalog.

Usage: agentic_prepare.sh [-h] <issue_number>

Arguments:
  issue_number    The GitHub issue number to fetch.

Flags:
  -h, --help      Show this help text.

Writes:
  issue.json      Issue metadata (number, title, body, current labels).
  labels.txt      Filtered label catalog (name - description), one per line.

Expects:
  GH_TOKEN             GitHub token with issues:read
  GITHUB_REPOSITORY    owner/repo
EOF
)"

log() { echo "$@" >&2; }

ARG_ISSUE_NUMBER=""

function main() {
  parse_args "$@"
  fetch_issue
  fetch_labels
}

: <<'DOC'
  Fetches the issue and extracts only the fields the triage prompt needs:
  number, title, body, and current label names.
DOC
function fetch_issue() {
  gh api "repos/${GITHUB_REPOSITORY}/issues/${ARG_ISSUE_NUMBER}" \
    | jq '{number, title, body, labels: [.labels[].name]}' \
    > issue.json
}

: <<'DOC'
  Fetches the repo's label catalog, removes labels the model should never
  suggest, and writes the survivors as "name — description" lines for
  injection into the triage prompt.
DOC
function fetch_labels() {
  local all_labels

  all_labels=$(gh api "repos/${GITHUB_REPOSITORY}/labels" --paginate)

  # Labels excluded from the triage prompt:
  #   agentic-*:      managed by the triage/implement workflows
  #   meta-labels:    require human judgment (duplicate, invalid, etc.)
  #   skip-changelog: release process label
  local meta_labels='[
    "duplicate", "invalid", "wontfix", "question",
    "help wanted", "good first issue", "skip-changelog"
  ]'

  echo "$all_labels" | jq -r --argjson meta "$meta_labels" '
    .[]
    | select(
        (.name | startswith("agentic-"))
        or (.name as $n | $meta | index($n) != null)
        | not
      )
    | "\(.name) — \(.description // "no description")"
  ' > labels.txt
}

: <<'DOC'
  Parses CLI arguments.
  See USAGE for argument descriptions.
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
        if [[ -z "$ARG_ISSUE_NUMBER" ]]; then
          ARG_ISSUE_NUMBER="$1"
        else
          log "Unexpected argument: $1"
          log "$USAGE"
          exit 1
        fi
        ;;
    esac
    shift
  done

  if [[ -z "$ARG_ISSUE_NUMBER" ]]; then
    log "Missing required argument: issue_number"
    log "$USAGE"
    exit 1
  fi
}

main "$@"
