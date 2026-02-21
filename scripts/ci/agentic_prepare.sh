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
  issue.json              Issue metadata (number, title, body, current labels).
  labels.txt              Filtered label catalog (name - description), one per line.
  auto_response.json      Synthetic triage response (only if body exceeds threshold).

Outputs (via GITHUB_OUTPUT):
  auto_triage=true        Set when the issue body is too long for model assessment.

Expects:
  GH_TOKEN             GitHub token with issues:read
  GITHUB_REPOSITORY    owner/repo
EOF
)"

log() { echo "$@" >&2; }

ARG_ISSUE_NUMBER=""
BODY_LENGTH_LIMIT=8000

function main() {
  parse_args "$@"

  local raw_issue
  raw_issue=$(gh api "repos/${GITHUB_REPOSITORY}/issues/${ARG_ISSUE_NUMBER}")

  if check_body_length "$raw_issue"; then
    write_issue "$raw_issue"
    fetch_labels
  fi
}

: <<'DOC'
  Checks the raw body length against BODY_LENGTH_LIMIT. If the body is too
  long, writes a synthetic response file and signals the workflow to skip
  the model call. Returns non-zero to short-circuit the rest of main.
DOC
function check_body_length() {
  local raw_issue="$1"
  local body_len

  body_len=$(echo "$raw_issue" | jq '.body | length')

  if [ "$body_len" -gt "$BODY_LENGTH_LIMIT" ]; then
    log "Issue body is $body_len chars (limit: $BODY_LENGTH_LIMIT); auto-triaging."
    write_auto_response "$body_len"
    echo "auto_triage=true" >> "${GITHUB_OUTPUT:-/dev/null}"
    return 1
  fi
}

: <<'DOC'
  Writes a synthetic triage response for issues that are too long to
  warrant a model call.
DOC
function write_auto_response() {
  local body_len="$1"

  jq -n --argjson len "$body_len" '{
    suggested_labels: [],
    agentic_confidence: 0,
    agentic_rationale: ("Auto-triaged: issue body is \($len) chars, exceeding the length threshold. Oversized issues are unlikely to be well-scoped for agentic implementation.")
  }' > auto_response.json
}

: <<'DOC'
  Extracts the fields the triage prompt needs from the raw API response:
  number, title, body (truncated to 4K chars), and current label names.
DOC
function write_issue() {
  local raw_issue="$1"

  echo "$raw_issue" \
    | jq '{number, title, body: (.body[:4000] // ""), labels: [.labels[].name]}' \
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
