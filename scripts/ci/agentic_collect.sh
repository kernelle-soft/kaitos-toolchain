#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Finds open issues not yet assessed by the agentic triage workflow.

Usage: agentic_collect.sh [-h]

Prints a JSON array of untriaged issue numbers to stdout.
Diagnostics are written to stderr.

Flags:
  -h, --help    Show this help text.

Expects:
  GH_TOKEN             GitHub token with issues:read
  GITHUB_REPOSITORY    owner/repo
EOF
)"

log() { echo "$@" >&2; }

function main() {
  parse_args "$@"

  local all_issues untriaged count

  all_issues=$(fetch_open_issues)
  untriaged=$(filter_untriaged "$all_issues")

  count=$(echo "$untriaged" | jq length)
  log "Found $count untriaged issue(s)"

  echo "$untriaged"
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
  Any issue carrying an agentic-* label (candidate, triaged, or greenlit)
  is considered processed and excluded from the result.
DOC
function filter_untriaged() {
  local all_issues="$1"

  echo "$all_issues" | jq '[.[]
    | select(
        .labels | map(.name) | any(startswith("agentic-"))
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
