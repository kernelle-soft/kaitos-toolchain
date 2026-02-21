#!/usr/bin/env bash
set -euo pipefail

# Finds open issues not yet triaged by the agentic workflow.
# Outputs: has_issues (bool) and numbers (JSON array) to $GITHUB_OUTPUT.
# Expects: GH_TOKEN, GITHUB_REPOSITORY, GITHUB_OUTPUT

repo="${GITHUB_REPOSITORY:?}"

untriaged=$(gh issue list \
  --repo "$repo" \
  --state open \
  --json number,labels \
  --limit 999 \
  -q '[.[]
    | select(
        ([.labels[].name]
          | (contains(["agentic-candidate"])
            or contains(["agentic-triaged"])
            or contains(["agentic-greenlit"])
          )
        ) | not
      )
    | .number
  ]')

count=$(echo "$untriaged" | jq length)
echo "Found $count untriaged issue(s)"

if [ "$count" -eq 0 ]; then
  echo "has_issues=false" >> "$GITHUB_OUTPUT"
  echo "numbers=[]" >> "$GITHUB_OUTPUT"
else
  echo "has_issues=true" >> "$GITHUB_OUTPUT"
  echo "numbers=$untriaged" >> "$GITHUB_OUTPUT"
fi
