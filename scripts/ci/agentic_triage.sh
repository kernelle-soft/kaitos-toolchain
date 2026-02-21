#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Applies agentic triage results to a GitHub issue.

Parses the structured JSON response from the triage model, applies any
suggested labels, tags the issue as agentic-candidate (>=80% confidence)
or agentic-triaged, and posts an assessment comment.

Usage: agentic_triage.sh [-h] <issue_number> <response_file>

Arguments:
  issue_number    The GitHub issue number to apply results to.
  response_file   Path to the JSON response file from the triage model.

Flags:
  -h, --help      Show this help text.

Expects:
  GH_TOKEN             GitHub token with issues:write
  GITHUB_REPOSITORY    owner/repo
EOF
)"

log() { echo "$@" >&2; }

ARG_ISSUE_NUMBER=""
ARG_RESPONSE_FILE=""

function main() {
  parse_args "$@"

  local confidence rationale suggested_csv agentic_label

  confidence=$(jq -r '.agentic_confidence' "$ARG_RESPONSE_FILE")
  rationale=$(jq -r '.agentic_rationale' "$ARG_RESPONSE_FILE")
  suggested_csv=$(jq -r '
    .suggested_labels | if length > 0 then join(",") else "" end
  ' "$ARG_RESPONSE_FILE")

  agentic_label=$(resolve_agentic_label "$confidence")

  apply_labels "$agentic_label" "$suggested_csv"
  post_comment "$confidence" "$rationale" "$suggested_csv" "$agentic_label"
}

: <<'DOC'
  Applies the agentic triage label and any model-suggested labels to the issue.
  Suggested labels are best-effort (the model may hallucinate a label that
  doesn't exist in the repo), so that call is non-fatal.
DOC
function apply_labels() {
  local agentic_label="$1"
  local suggested_csv="$2"

  if [[ -n "$suggested_csv" ]]; then
    gh issue edit "$ARG_ISSUE_NUMBER" \
      --add-label "$suggested_csv" \
      --repo "$GITHUB_REPOSITORY" || true
  fi

  gh issue edit "$ARG_ISSUE_NUMBER" \
    --add-label "$agentic_label" \
    --repo "$GITHUB_REPOSITORY"
}

: <<'DOC'
  Returns "agentic-candidate" if confidence meets the threshold (>=80),
  "agentic-triaged" otherwise.
DOC
function resolve_agentic_label() {
  local confidence="$1"

  if [[ $(echo "$confidence" | jq '. >= 80') == "true" ]]; then
    echo "agentic-candidate"
  else
    echo "agentic-triaged"
  fi
}

: <<'DOC'
  Writes the triage assessment markdown to stdout.
DOC
function format_comment() {
  local confidence="$1" rationale="$2"
  local suggested_csv="$3" agentic_label="$4"

  printf '%s\n' \
    "### Agentic Triage Assessment" \
    "" \
    "**Agentic fitness:** ${confidence}%" \
    "**Rationale:** ${rationale}" \
    "**Labels suggested:** ${suggested_csv:-none}" \
    "**Triage result:** \`${agentic_label}\`"

  if [[ "$agentic_label" = "agentic-candidate" ]]; then
    printf '\n%s\n%s\n' \
      "> This issue looks like a good candidate for agentic implementation." \
      "> A maintainer can re-tag as \`agentic-greenlit\` to approve."
  fi
}

: <<'DOC'
  Formats and posts the triage assessment as a comment on the issue.
DOC
function post_comment() {
  local tmp
  tmp=$(mktemp)
  trap "rm -f '$tmp'" EXIT INT TERM

  format_comment "$@" > "$tmp"

  gh issue comment "$ARG_ISSUE_NUMBER" \
    --body-file "$tmp" \
    --repo "$GITHUB_REPOSITORY"
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
        elif [[ -z "$ARG_RESPONSE_FILE" ]]; then
          ARG_RESPONSE_FILE="$1"
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

  if [[ -z "$ARG_RESPONSE_FILE" ]]; then
    log "Missing required argument: response_file"
    log "$USAGE"
    exit 1
  fi
}

main "$@"
