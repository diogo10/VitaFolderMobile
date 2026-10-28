#!/usr/bin/env bash
# Builds the repository's dev container image and runs one BakeAgent task in it.
#
# `.devcontainer/` is shared with developers and is deliberately not modified
# for CI: this script builds that very Dockerfile and runs the task inside the
# resulting image. Everything CI-specific (the pinned OpenCode CLI, dependency
# resolution, the agent run and the verification gate) lives in
# `tool/bakeagent_container.sh`, which is the command executed in the container.
#
# Usage: bash tool/bakeagent_run.sh
#   The checkout must already contain `.bakeagent/task.json` and
#   `.bakeagent/prompt.txt`; the workflow writes them.
#
# Environment:
#   BAKEAGENT_IMAGE  image name to build (default: bakeagent-devcontainer)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ ! -s .bakeagent/task.json ] || [ ! -s .bakeagent/prompt.txt ]; then
  echo "::error::.bakeagent/task.json or .bakeagent/prompt.txt is missing; the workflow did not prepare a task."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "::error::docker is not available; cannot build the dev container image."
  exit 1
fi

IMAGE="${BAKEAGENT_IMAGE:-bakeagent-devcontainer}"
TAG="${GITHUB_RUN_ID:-local}"

echo "Building $IMAGE:$TAG from .devcontainer/Dockerfile..."
docker build \
  --file .devcontainer/Dockerfile \
  --tag "$IMAGE:$TAG" \
  .devcontainer

echo "Running the task in the dev container..."
STATUS=0
docker run --rm --init \
  --volume "$ROOT:/workspace" \
  --workdir /workspace \
  "$IMAGE:$TAG" \
  bash tool/bakeagent_container.sh || STATUS=$?

# The image has no remoteUser, so everything in the container runs as root and
# the files it created - the git index included - belong to root. Give the
# workspace back before the workflow touches git, otherwise `git add` cannot
# write the index. `sudo -n` is only true on the CI runner; on a developer
# machine Docker already maps root to the current user.
if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  sudo chown -R "$(id -u):$(id -g)" "$ROOT"
fi

exit "$STATUS"
