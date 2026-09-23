#!/usr/bin/env bash

## Usage: bakehub-setup.sh <API_KEY>
## This script sets up the development environment for a Bakehub task. 
## It fetches pending tasks or improvement feedback from the Bakehub API and runs them using opencode.

API_KEY=$1

## Setup env keys
if [ -f ".env" ]; then
  set -a
  source ".env"
  set +a
fi

REPO_URL="https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/' | sed 's/.*github.com[:/]\(.*\)/\1/')"
BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)"
BRANCH_NAME_ESCAPED=$(printf '%s' "$BRANCH_NAME" | sed 's/\//%2F/g')

echo ""
REPO_NAME=$(basename -s .git "$REPO_URL")
REPO_NAME_ESCAPED=$(printf '%s' "$REPO_NAME" | sed 's/\//%2F/g')
response_tasks=$(curl -H "x-api-key: $API_KEY" "https://ajfjzspcfmryesrkxuca.supabase.co/functions/v1/api?action=get-pending-tasks&repository_name=$REPO_NAME_ESCAPED&branch_name=$BRANCH_NAME_ESCAPED")

echo ""
echo "Tasks fetched successfully:"
echo "$response_tasks" | jq .
echo ""

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to parse response_tasks JSON. Please install jq and try again."
  exit 1
fi

API_BASE="https://ajfjzspcfmryesrkxuca.supabase.co/functions/v1/api"

# 1. Improvement check (priority): if the user provided feedback on an open PR
improvement_task=$(echo "$response_tasks" | jq -c '((.tasks // .) | map(select((.feedback // "") != "")) | .[0])')

if [ -n "$improvement_task" ] && [ "$improvement_task" != "null" ]; then
  TASK_ID=$(echo "$improvement_task" | jq -r '.id')
  TASK_TITLE=$(echo "$improvement_task" | jq -r '.title')
  TASK_FEEDBACK=$(echo "$improvement_task" | jq -r '.feedback')

  echo "RUN opencode improvement on existing pull request"

  opencode run --title "Improvement on PR: $TASK_TITLE" "A pull request is already open on branch $BRANCH_NAME. Address the following feedback: $TASK_FEEDBACK. Make the necessary code edits, run the tests, then commit and push to origin $BRANCH_NAME. Do NOT open a new pull request — pushing to the existing branch updates the open pull request."

  curl -s -X POST -H "x-api-key: $API_KEY" -H "Content-Type: application/json" \
    -d "{\"task_id\": \"$TASK_ID\"}" \
    "$API_BASE?action=clear-task-feedback" >/dev/null
  echo ""
  echo "Improvement run finished and feedback cleared."
  exit 0
fi

# 2. Regular pending task flow
pending_task=$(echo "$response_tasks" | jq -c '((.tasks // .) | map(select(.status == "pending")) | .[0])')

if [ -z "$pending_task" ] || [ "$pending_task" = "null" ]; then
  echo "No pending tasks found."
  exit 0
fi

TASK_TITLE=$(echo "$pending_task" | jq -r '.title')
TASK_DESCRIPTION=$(echo "$pending_task" | jq -r '.description')

echo "RUN opencode tasks"

opencode run --title "$TASK_TITLE" "$TASK_DESCRIPTION - do the task and create a pull request with the changes."
