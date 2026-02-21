#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Applies agentic triage results to a GitHub issue.

Parses the structured JSON response from the triage model, applies any
suggested labels, tags the issue as agentic-candidate (>90% confidence)
or agentic-triaged, and posts an assessment comment.

Usage: agentic_triage.sh [-h]

Flags:
  -h, --help    Show this help text.

Expects:
  GH_TOKEN             GitHub token with issues:write
  GITHUB_REPOSITORY    owner/repo
  ISSUE_NUMBER         Issue number to triage
  RESPONSE             JSON response from the triage model
EOF
)"

command -v log &>/dev/null || log() { echo "$@"; }

function main() {
  parse_args "$@"

  local confidence rationale suggested agentic_label suggested_list
  local response="$RESPONSE"

  confidence=$(echo "$response" | jq -r '.agentic_confidence')
  rationale=$(echo "$response" | jq -r '.agentic_rationale')
  suggested=$(echo "$response" | jq -r '.suggested_labels[]' 2>/dev/null || true)

  apply_suggested_labels "$suggested"
  agentic_label=$(resolve_agentic_label "$confidence")
  apply_agentic_label "$agentic_label"

  suggested_list=$(echo "$response" | jq -r '.suggested_labels | join(", ")' 2>/dev/null || echo "none")
  post_comment "$confidence" "$rationale" "$suggested_list" "$agentic_label"
}

: <<'DOC'
  Adds the model's suggested labels to the issue. Non-fatal if a label
  does not exist (the model may occasionally hallucinate one).
DOC
function apply_suggested_labels() {
  local suggested="$1"

  if [[ -n "$suggested" ]]; then
    local label_csv
    label_csv=$(echo "$suggested" | paste -sd, -)
    gh issue edit "$ISSUE_NUMBER" --add-label "$label_csv" \
      --repo "$GITHUB_REPOSITORY" || true
  fi
}

: <<'DOC'
  Returns "agentic-candidate" if confidence exceeds the threshold,
  "agentic-triaged" otherwise.
DOC
function resolve_agentic_label() {
  local confidence="$1"

  if [ "$(echo "$confidence > 90" | bc -l)" -eq 1 ]; then
    echo "agentic-candidate"
  else
    echo "agentic-triaged"
  fi
}

function apply_agentic_label() {
  local label="$1"
  gh issue edit "$ISSUE_NUMBER" --add-label "$label" --repo "$GITHUB_REPOSITORY"
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

  gh issue comment "$ISSUE_NUMBER" --body-file comment.md --repo "$GITHUB_REPOSITORY"
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

main "$@"
