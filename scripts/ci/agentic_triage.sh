#!/usr/bin/env bash
set -euo pipefail

# Applies agentic triage results to a GitHub issue: labels it and posts a comment.
# Expects: GH_TOKEN, GITHUB_REPOSITORY, ISSUE_NUMBER, RESPONSE (JSON from model)

repo="${GITHUB_REPOSITORY:?}"
issue_number="${ISSUE_NUMBER:?}"
response="${RESPONSE:?}"

confidence=$(echo "$response" | jq -r '.agentic_confidence')
rationale=$(echo "$response" | jq -r '.agentic_rationale')
suggested=$(echo "$response" | jq -r '.suggested_labels[]' 2>/dev/null || true)

if [ -n "$suggested" ]; then
  label_csv=$(echo "$suggested" | paste -sd, -)
  gh issue edit "$issue_number" --add-label "$label_csv" \
    --repo "$repo" || true
fi

if [ "$(echo "$confidence > 90" | bc -l)" -eq 1 ]; then
  agentic_label="agentic-candidate"
else
  agentic_label="agentic-triaged"
fi

gh issue edit "$issue_number" --add-label "$agentic_label" --repo "$repo"

suggested_list=$(echo "$response" | jq -r '.suggested_labels | join(", ")' 2>/dev/null || echo "none")

{
  echo "### 🤖 Agentic Triage Assessment"
  echo ""
  echo "**Agentic fitness:** ${confidence}%"
  echo "**Rationale:** ${rationale}"
  echo "**Labels suggested:** ${suggested_list}"
  echo "**Triage result:** \`${agentic_label}\`"

  if [ "$agentic_label" = "agentic-candidate" ]; then
    echo ""
    echo "> This issue looks like a good candidate for agentic implementation."
    echo "> A maintainer can re-tag as \`agentic-greenlit\` to approve."
  fi
} > comment.md

gh issue comment "$issue_number" --body-file comment.md --repo "$repo"
