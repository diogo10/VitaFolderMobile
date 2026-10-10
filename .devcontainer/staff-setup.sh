#!/usr/bin/env bash

## Usage: staff-setup.sh <API_KEY>
## Staff Engineer strategy run: asks BakeAgent for the queued run, executes
## opencode once with the engineer's role, and posts the proposed tasks back.

set -uo pipefail

API_KEY=$1
API_BASE="https://ajfjzspcfmryesrkxuca.supabase.co/functions/v1/api"

if [ -f ".env" ]; then
  set -a
  source ".env"
  set +a
fi

REPO_NAME=$(basename -s .git "$(git remote get-url origin)")
BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)"
REPO_NAME_ESCAPED=$(printf '%s' "$REPO_NAME" | sed 's/\//%2F/g')
BRANCH_NAME_ESCAPED=$(printf '%s' "$BRANCH_NAME" | sed 's/\//%2F/g')

run=$(curl -s -H "x-api-key: $API_KEY" "$API_BASE?action=get-staff-run&repository_name=$REPO_NAME_ESCAPED&branch_name=$BRANCH_NAME_ESCAPED")
echo "$run" | jq . || true

RUN_ID=$(echo "$run" | jq -r '.run.id // empty')
ROLE=$(echo "$run" | jq -r '.run.role // empty')

if [ -z "$RUN_ID" ]; then
  echo "No queued staff engineer run for this branch."
  exit 0
fi

PROMPT="$ROLE — analyse this repository and propose concrete tasks; output a JSON array of {title, description} and nothing else."

OUTPUT=$(opencode run "$PROMPT")
echo "$OUTPUT"

jq -n --arg run_id "$RUN_ID" --arg output "$OUTPUT" '{run_id: $run_id, output: $output}' \
  | curl -s -X POST -H "x-api-key: $API_KEY" -H "Content-Type: application/json" \
      --data-binary @- "$API_BASE?action=submit-staff-suggestions" | jq . || true


echo "remove codespace $CODESPACE_NAME"
gh codespace delete --codespace "$CODESPACE_NAME" --force


