#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Assigns the Copilot coding agent to all open issues tagged agentic-greenlit.

Usage: agentic_implement.sh [-h]

Copilot creates a branch and opens a PR for each assigned issue. Intended
to be triggered after a human reviews agentic-candidate issues and re-tags
the approved ones.

Flags:
  -h, --help    Show this help text.

Expects:
  GH_TOKEN             GitHub token with issues:write
  GITHUB_REPOSITORY    owner/repo
EOF
)"

command -v log &>/dev/null || log() { echo "$@"; }

function main() {
  parse_args "$@"

  local issues count

  issues=$(fetch_greenlit_issues)
  count=$(echo "$issues" | jq length)
  log "Found $count greenlit issue(s)"

  if [ "$count" -eq 0 ]; then
    log "Nothing to do."
    exit 0
  fi

  local number
  for number in $(echo "$issues" | jq -r '.[]'); do
    assign_copilot "$number"
  done
}

: <<'DOC'
  Grabs the list of issues that have been greenlit for agentic autoimplementation.
DOC
function fetch_greenlit_issues() {
  gh issue list \
    --repo "$GITHUB_REPOSITORY" \
    --state open \
    --label "agentic-greenlit" \
    --json number \
    --limit 999 \
    -q '[.[].number]'
}

: <<'DOC'
  Assigns Copilot to a single issue via the REST assignees endpoint.
  Non-fatal — logs a warning and continues if assignment fails.
DOC
function assign_copilot() {
  local number="$1"

  echo "::group::Issue #$number"
  log "Assigning Copilot to issue #$number..."

  gh api "repos/${GITHUB_REPOSITORY}/issues/${number}/assignees" \
    --method POST \
    -f "assignees[]=copilot" \
    --silent \
  && log "Assigned." \
  || echo "::warning::Failed to assign Copilot to issue #$number"

  echo "::endgroup::"
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
