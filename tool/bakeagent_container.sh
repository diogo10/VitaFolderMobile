#!/usr/bin/env bash
# Runs the BakeAgent task inside the dev container image (CI entry point).
#
# This is the command `tool/bakeagent_run.sh` executes in the container. The
# workflow (on the host) has already written `.bakeagent/task.json` and
# `.bakeagent/prompt.txt`, and it owns git: this script only runs the agent and
# the verification gate. Nothing here needs a GitHub token, so the agent cannot
# commit, push or open a pull request on its own.
#
# The `.devcontainer` image installs OpenCode with the upstream floating
# installer, so the first thing this script does is put the pinned,
# checksum-verified CLI that the review job uses on PATH instead (see
# tool/install_opencode_cli.sh). A task run is then reproducible.
#
# Usage: bash tool/bakeagent_container.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

PROMPT_FILE=".bakeagent/prompt.txt"
TASK_FILE=".bakeagent/task.json"
if [ ! -s "$PROMPT_FILE" ] || [ ! -s "$TASK_FILE" ]; then
  echo "::error::$PROMPT_FILE or $TASK_FILE is missing; the workflow did not prepare a task."
  exit 1
fi

TITLE="$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["title"])' "$TASK_FILE")"

# /usr/local/bin is on PATH and before the image's per-user install location,
# so the verified binary is the one that runs.
export OPENCODE_INSTALL_DIR="${OPENCODE_INSTALL_DIR:-/usr/local/bin}"
OPENCODE_BIN="$OPENCODE_INSTALL_DIR/opencode"
tool/install_opencode_cli.sh

# The checkout is mounted from the runner user but everything here runs as
# root: git refuses to work in a directory owned by somebody else.
git config --global --add safe.directory "$PWD" 2>/dev/null || true

MODEL="$(sed -nE 's/^[[:space:]]*"model":[[:space:]]*"([^"]+)".*/\1/p' opencode.jsonc | head -n 1)"
echo "BakeAgent model: ${MODEL:-<opencode.jsonc default>}"

# Same quota/credit signals as the review job: a free-tier limit is reported
# as an error, never as a silent no-op.
QUOTA_PATTERN='provider\.quota|free usage limit|"status":429|too many requests|insufficient (credit|funds|balance)|payment required|out of credits'

# Resolve dependencies once, so the agent and the gate do not race on them.
echo "Resolving dependencies..."
flutter pub get
for pkg in packages/*/; do
  (cd "$pkg" && flutter pub get)
done

# Warm the provider catalog up: on a cold machine the first CLI call can start
# before models.dev is loaded and the configured model then has no route.
if [ -n "$MODEL" ]; then
  for attempt in 1 2 3 4 5 6; do
    if "$OPENCODE_BIN" models 2>/dev/null | grep -qF -- "$MODEL"; then
      break
    fi
    echo "The model $MODEL is not routable yet (attempt $attempt)."
    if [ "$attempt" -lt 6 ]; then
      sleep 5
    fi
  done
fi

run_opencode() {
  local log="$1"
  shift
  local status=0
  set +e
  "$OPENCODE_BIN" run --standalone "$@" 2>&1 | tee "$log"
  status="${PIPESTATUS[0]}"
  set -e
  return "$status"
}

echo ""
echo "Running the task: $TITLE"
echo ""

AGENT_STATUS=0
run_opencode /tmp/opencode.log --title "$TITLE" "$(cat "$PROMPT_FILE")" || AGENT_STATUS=$?

if [ "$AGENT_STATUS" -ne 0 ]; then
  if grep -qiE "$QUOTA_PATTERN" /tmp/opencode.log; then
    echo "::error::The model ${MODEL:-configured in opencode.jsonc} is out of free quota/credits, so the task did not run. Switch opencode.jsonc to a model with available quota (and provide its provider key as a repository secret) and re-run."
  else
    echo "::error::opencode exited with status $AGENT_STATUS; see the log above."
  fi
  exit 1
fi

# The task only counts when the change passes the same checks as CI: a pull
# request that is red on arrival would only waste a review run.
verify() {
  flutter analyze --no-fatal-infos --fatal-warnings
  flutter test
}

if ! verify >/tmp/verify.log 2>&1; then
  echo "::warning::The verification gate failed; asking the agent to fix it."
  for attempt in 1 2; do
    tail -c 20000 /tmp/verify.log > /tmp/verify_tail.log
    {
      echo "The change does not pass the verification gate yet."
      echo ""
      echo "Fix the failures below. Do not disable, skip or weaken a check,"
      echo "and do not change unrelated code. Do not run git commit or git push."
      echo ""
      echo '```'
      cat /tmp/verify_tail.log
      echo '```'
    } > /tmp/fix_prompt.txt

    echo "Fix attempt $attempt"
    run_opencode /tmp/opencode_fix.log \
      --title "Fix the failing checks: $TITLE" \
      "$(cat /tmp/fix_prompt.txt)" || true

    if verify >/tmp/verify.log 2>&1; then
      break
    fi
  done
fi

if ! verify; then
  echo "::error::The change does not pass flutter analyze + flutter test; nothing was pushed."
  exit 1
fi

echo ""
echo "The verification gate passed."
