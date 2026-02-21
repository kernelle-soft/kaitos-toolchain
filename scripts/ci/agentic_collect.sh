#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Finds open issues not yet assessed by the agentic triage workflow.

Usage: agentic_collect.sh [-h]

Outputs the list of untriaged issue numbers as a JSON array to \$GITHUB_OUTPUT
for use as a matrix in downstream workflow jobs.

Flags:
  -h, --help    Show this help text.

Expects:
  GH_TOKEN             GitHub token with issues:read
  GITHUB_REPOSITORY    owner/repo
  GITHUB_OUTPUT        Actions output file
EOF
)"

command -v log &>/dev/null || log() { echo "$@"; }

function main() {
  parse_args "$@"

  local all_issues untriaged count

  all_issues=$(fetch_open_issues)
  untriaged=$(filter_untriaged "$all_issues")

  count=$(echo "$untriaged" | jq length)
  log "Found $count untriaged issue(s)"

  if [ "$count" -eq 0 ]; then
    echo "has_issues=false" >> "$GITHUB_OUTPUT"
    echo "numbers=[]" >> "$GITHUB_OUTPUT"
  else
    echo "has_issues=true" >> "$GITHUB_OUTPUT"
    echo "numbers=$untriaged" >> "$GITHUB_OUTPUT"
  fi
}

function fetch_open_issues() {
  gh issue list \
    --repo "$GITHUB_REPOSITORY" \
    --state open \
    --json number,labels \
    --limit 999
}

: <<'DOC'
  Filters out issues that have already been processed by the agentic workflow.
  An issue is considered "processed" if it carries any of the three agentic
  lifecycle labels: agentic-candidate, agentic-triaged, or agentic-greenlit.
DOC
function filter_untriaged() {
  local all_issues="$1"

  echo "$all_issues" | jq '[.[]
    | select(
        .labels | map(.name)
        | any(
            . == "agentic-candidate"
            or . == "agentic-triaged"
            or . == "agentic-greenlit"
          )
        | not
      )
    | .number
  ]'
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
