#!/usr/bin/env bash
set -euo pipefail
eval "${CI_ENVRC:-}"

USAGE="$(cat <<EOF
Handler for CI/CD git operations. Not generally for manual use.

Usage: git_commit.sh [flags...]

Flags:
  -a, --all      Commit all changed files, including added and deleted files.
  -m, --message  Supply a custom git message.
EOF
)"

FLAG_ALL=false
STR_COMMIT_MSG="$(cat <<EOF
chore: automated commit [skip ci]

This commit was made automatically via Github Actions.
EOF
)"

function main() {
  local -a commit_args=()
  parse_args "$@"

  if [[ $FLAG_ALL = true ]]; then
    commit_args+=(-a)
    git add -A
  fi

  # Skip if nothing to commit
  if git diff --cached --quiet; then
    log "Nothing to commit"
    exit 0
  fi

  git commit "${commit_args[@]}" -m "$STR_COMMIT_MSG"
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
