#!/usr/bin/env bash
set -euo pipefail

USAGE="$(cat <<EOF
Handler for CI/CD git operations. Not for manual use.

Usage: cicd_git_commit.sh [flags...]

Flags:
  -a, --all      Commit all changed files, included added and deleted files.
  -m, --message  Supply a custom git message.
EOF
)"

FLAG_ALL=false
STR_COMMIT_MSG="$(cat <<<EOF
chore: automated commit [skip ci]

This commit was made automatically via Github Actions.
EOF)"

function main() {
  parse_args "$@"

  # TODO - write the actual logic for performing the commits.
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
        shift
        ;;
      -m|--message)
        shift # discard actual flag.
        STR_COMMIT_MSG="$1"
        shift
        ;;
			-h|--help)	log "$USAGE" && exit 0;;
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