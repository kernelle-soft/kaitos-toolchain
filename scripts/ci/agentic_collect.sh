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

ISSUE_SOFT_CAP=100

function main() {
  parse_args "$@"

  local untriaged count

  untriaged=$(fetch_untriaged_issues)

  count=$(echo "$untriaged" | jq length)

  if [ "$count" -gt "$ISSUE_SOFT_CAP" ]; then
    log "WARNING: untriaged issues exceed cap of $ISSUE_SOFT_CAP."
    log "Only the oldest $ISSUE_SOFT_CAP will be triaged this run."
    untriaged=$(echo "$untriaged" | jq ".[:$ISSUE_SOFT_CAP]")
  fi

  echo "$untriaged"
}

: <<'DOC'
  Searches for open issues that have not yet been processed by the agentic
  workflow (no agentic-* labels). Results are sorted oldest-first so the
  backlog drains FIFO. Fetches one beyond the soft cap to detect overflow.
DOC
function fetch_untriaged_issues() {
  gh search issues \
    --repo "$GITHUB_REPOSITORY" \
    --state open \
    --sort created \
    --order asc \
    --json number \
    --limit "$((ISSUE_SOFT_CAP + 1))" \
    -- -label:agentic-triaged -label:agentic-candidate -label:agentic-greenlit \
    | jq '[.[].number]'
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
