#!/usr/bin/env bash
set -euo pipefail

# Fetches issue details and repo label catalog for the triage prompt.
# Outputs: issue.json, labels.txt in the current directory.
# Expects: GH_TOKEN, GITHUB_REPOSITORY
# Args: $1 = issue number

repo="${GITHUB_REPOSITORY:?}"
issue_number="${1:?usage: agentic_prepare.sh <issue_number>}"

gh api "repos/${repo}/issues/${issue_number}" \
  | jq '{number, title, body, labels: [.labels[].name]}' \
  > issue.json

# Fetch labels, excluding workflow-managed and meta-labels so the model
# only sees labels it's allowed to suggest.
gh api "repos/${repo}/labels" --paginate \
  -q '.[]
    | select(.name |
        test("^(agentic-|duplicate$|invalid$|wontfix$|question$|help wanted$|good first issue$|skip-changelog$)")
        | not
      )
    | "\(.name) — \(.description // "no description")"' \
  > labels.txt
