#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Applies agentic triage results to a GitHub issue.

Parses the structured JSON response from the triage model, applies any
suggested labels, tags the issue as agentic-candidate (>90% confidence)
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

command -v log &>/dev/null || log() { echo "$@"; }

ARG_ISSUE_NUMBER=""
ARG_RESPONSE_FILE=""

function main() {
  parse_args "$@"

  local response confidence rationale suggested agentic_label suggested_list

  response="$(cat "$ARG_RESPONSE_FILE")"

  confidence="$(echo "$response" | jq -r '.agentic_confidence')"
  rationale="$(echo "$response" | jq -r '.agentic_rationale')"

  # .suggested_labels is always present (schema-enforced) but may be empty.
  suggested="$(echo "$response" | jq -r '.suggested_labels[]' 2>/dev/null || true)"

  apply_suggested_labels "$suggested"

  agentic_label="$(resolve_agentic_label "$confidence")"

  gh issue edit "$ARG_ISSUE_NUMBER" \
    --add-label "$agentic_label" \
    --repo "$GITHUB_REPOSITORY"

  suggested_list="$(
    echo "$response" \
    | jq -r '.suggested_labels | join(", ")' 2>/dev/null \
    || echo "none"
  )"

  post_comment "$confidence" "$rationale" "$suggested_list" "$agentic_label"
}

: <<'DOC'
  Adds the model's suggested labels to the issue. Non-fatal if a label
  does not exist (the model may occasionally hallucinate one).
DOC
function apply_suggested_labels() {
  local suggested="$1"

  if [[ -z "$suggested" ]]; then
    return
  fi

  # Join newline-delimited label names into the comma-separated
  # format that gh --add-label expects.
  local label_csv
  label_csv="$(echo "$suggested" | paste -sd, -)"

  gh issue edit "$ARG_ISSUE_NUMBER" \
    --add-label "$label_csv" \
    --repo "$GITHUB_REPOSITORY" || true
}

: <<'DOC'
  Returns "agentic-candidate" if confidence exceeds the threshold,
  "agentic-triaged" otherwise.
DOC
function resolve_agentic_label() {
  local confidence="$1"

  # bc -l outputs 1 (true) or 0 (false) for relational expressions;
  # bash doesn't support floating-point comparison natively.
  if [ "$(echo "$confidence > 90" | bc -l)" -eq 1 ]; then
    echo "agentic-candidate"
  else
    echo "agentic-triaged"
  fi
}

: <<'DOC'
  Posts the triage assessment as a comment on the issue.
DOC
function post_comment() {
  local confidence="$1" rationale="$2"
  local suggested_list="$3" agentic_label="$4"

  {
    echo "### Agentic Triage Assessment"
    echo ""
    echo "**Agentic fitness:** ${confidence}%"
    echo "**Rationale:** ${rationale}"
    echo "**Labels suggested:** ${suggested_list}"
    echo "**Triage result:** \`${agentic_label}\`"

    if [[ "$agentic_label" = "agentic-candidate" ]]; then
      echo ""
      echo "> This issue looks like a good candidate for agentic implementation."
      echo "> A maintainer can re-tag as \`agentic-greenlit\` to approve."
    fi
  } > comment.md

  gh issue comment "$ARG_ISSUE_NUMBER" \
    --body-file comment.md \
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
