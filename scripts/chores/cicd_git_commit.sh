#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"

USAGE="$(cat <<EOF
Handler for CI/CD git operations. Not for manual use.

Usage: cicd_git_commit.sh [flags...]

Flags:
  -a, --all      Commit all changed files, including added and deleted files.
  -m, --message  Supply a custom git message.
EOF
)"

source "$REPO_ROOT/scripts/shared/log.func.sh"

FLAG_ALL=false
STR_COMMIT_MSG="$(cat <<EOF
chore: automated commit [skip ci]

This commit was made automatically via Github Actions.
EOF
)"

function main() {
  local commit_args=""
  parse_args "$@"

  if [[ $FLAG_ALL = true ]]; then
    commit_args="$commit_args -a"
  fi

  git commit "$commit_args -m $STR_COMMIT_MSG"
}

: <<'DOC'
  Parses CLI flags. 
  See USAGE for flag descriptions.
DOC
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -a|--all)
        FLAG_ALL=true
        ;;
      -m|--message)
        shift # discard actual flag.
        STR_COMMIT_MSG="$1"
        ;;
      -h|--help)
        log "$USAGE" && exit 0
        ;;
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