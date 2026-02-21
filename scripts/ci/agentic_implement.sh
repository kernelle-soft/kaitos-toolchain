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

log() { echo "$@" >&2; }

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
    try_assign_copilot "$number"
  done
}

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
  Adds "copilot" to the assignees list for the given issue number.
DOC
function add_copilot_assignee() {
  local number="$1"

  gh api "repos/${GITHUB_REPOSITORY}/issues/${number}/assignees" \
    --method POST \
    -f "assignees[]=copilot" \
    --silent
}

: <<'DOC'
  Attempts to assign Copilot to a single issue.
  Non-fatal — logs a warning and continues if assignment fails.
DOC
function try_assign_copilot() {
  local number="$1"

  # Workflow commands: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions
  echo "::group::Issue #$number"
  log "Assigning Copilot to issue #$number..."

  if add_copilot_assignee "$number"; then
    log "Assigned."
  else
    echo "::warning::Failed to assign Copilot to issue #$number"
  fi

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
