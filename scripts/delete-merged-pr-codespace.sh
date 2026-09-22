#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  echo "Usage: $0 <pull-request-number> [repository]" >&2
  echo "Example: $0 123 diogo10/VitaFolderMobile" >&2
  exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || usage

PR_NUMBER="$1"
REPOSITORY="${2:-${GITHUB_REPOSITORY:-}}"

[[ "$PR_NUMBER" =~ ^[0-9]+$ ]] || {
  echo "Pull request number must be numeric: $PR_NUMBER" >&2
  exit 2
}
[[ -n "$REPOSITORY" ]] || {
  echo "A repository is required as the second argument or GITHUB_REPOSITORY." >&2
  exit 2
}

command -v gh >/dev/null 2>&1 || {
  echo "GitHub CLI (gh) is required." >&2
  exit 1
}
command -v jq >/dev/null 2>&1 || {
  echo "jq is required." >&2
  exit 1
}

# The head branch remains available in the PR metadata even if the branch was
# deleted as part of the merge.
pr_json="$(gh pr view "$PR_NUMBER" --repo "$REPOSITORY" --json headRefName,headRepository)"
head_branch="$(jq -r '.headRefName // empty' <<<"$pr_json")"
head_repository="$(jq -r '.headRepository.nameWithOwner // empty' <<<"$pr_json")"

[[ -n "$head_branch" ]] || {
  echo "Could not determine the head branch for $REPOSITORY#$PR_NUMBER." >&2
  exit 1
}

# Codespaces are owned by the authenticated gh user. Match both the base and
# head repository so this also works for pull requests opened from a fork.
codespaces="$(gh codespace list --json name,repository,branch --limit 1000 | jq -r \
  --arg base_repository "$REPOSITORY" \
  --arg head_repository "$head_repository" \
  --arg head_branch "$head_branch" \
  '.[]
   | select(.branch == $head_branch)
   | select(.repository == $base_repository or ($head_repository != "" and .repository == $head_repository))
   | .name')"

if [[ -z "$codespaces" ]]; then
  echo "No Codespace found for $REPOSITORY#$PR_NUMBER (branch: $head_branch)."
  exit 0
fi

while IFS= read -r codespace_name; do
  [[ -n "$codespace_name" ]] || continue
  echo "Deleting Codespace: $codespace_name"
  gh codespace delete --codespace "$codespace_name" --force
done <<<"$codespaces"
