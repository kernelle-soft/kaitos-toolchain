#!/usr/bin/env bash
set -euo pipefail

# Assigns Copilot to all open issues tagged agentic-greenlit.
# Expects: GH_TOKEN, GITHUB_REPOSITORY

repo="${GITHUB_REPOSITORY:?}"

issues=$(gh issue list \
  --repo "$repo" \
  --state open \
  --label "agentic-greenlit" \
  --json number \
  --limit 999 \
  -q '[.[].number]')

count=$(echo "$issues" | jq length)
echo "Found $count greenlit issue(s)"

if [ "$count" -eq 0 ]; then
  echo "Nothing to do."
  exit 0
fi

for number in $(echo "$issues" | jq -r '.[]'); do
  echo "::group::Issue #$number"
  echo "Assigning Copilot to issue #$number..."

  gh api "repos/${repo}/issues/${number}/assignees" \
    --method POST -f "assignees[]=copilot" \
    --silent \
  && echo "Assigned." \
  || echo "::warning::Failed to assign Copilot to issue #$number"

  echo "::endgroup::"
done
