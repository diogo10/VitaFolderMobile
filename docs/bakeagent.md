# BakeAgent (Bakehub tasks)

BakeAgent runs one Bakehub task at a time in the **same image a developer
uses**, and publishes the result as a pull request.

The dev container is shared with developers and is not modified for CI:

| Path | Role |
| --- | --- |
| `.devcontainer/Dockerfile` | The image. Built as-is by `tool/bakeagent_run.sh`. |
| `tool/bakeagent_run.sh` | Host side: builds that Dockerfile and runs the task container. |
| `tool/bakeagent_container.sh` | Runs *inside* the container: pinned CLI, dependencies, agent, gate. |
| `tool/bakehub_tasks.py` | Task selection, prompt and branch slug (unit tested). |

Because the image is started with `docker run` and not with the devcontainer
CLI, no devcontainer lifecycle script runs in CI: `postStartCommand` in
`.devcontainer/devcontainer.json` cannot consume a task behind the workflow's
back.

## The workflow

`Actions -> bakeagent-run -> Run workflow`. Leave the inputs empty to run the
next queued task, or fill `task_title` (and optionally `task_description`) to
run a one-off task that does not touch the queue.

1. **Test the tooling.** `python3 -m unittest tool.test_bakehub_tasks` runs
   before anything else: a broken parser, prompt or slug fails the run in
   seconds instead of after the image build. Nothing is added to `ci.yml`,
   which stays as it is.
2. **Resolve the task.** `tool/bakehub_tasks.py select` calls the Bakehub API
   (`get-pending-tasks`) for this repository and the dispatched branch and
   picks the first task with reviewer feedback, else the first `status ==
   "pending"` task. The manual inputs win over the queue. The task is written
   to `.bakeagent/task.json` (gitignored) and exported as step outputs.
3. **Prepare the branch.** `bakeagent/<slug>`, unless an open pull request
   already carries the task id in its body:
   - feedback task: the run checks out that pull request's branch and pushes
     the fix onto it (no second PR);
   - pending task: the run stops, because the task already produced an open
     pull request. Bakehub never marks pending tasks as done, so without this
     guard every dispatch would open another PR for the same task.
4. **Write the prompt.** `tool/bakehub_tasks.py prompt` renders the task, the
   reviewer feedback and the project rules (`AGENTS.md`) into
   `.bakeagent/prompt.txt`. The prompt forbids `git commit`, `git push` and
   `gh`: the workflow owns the GitHub token, the agent never sees it.
5. **Build and run the dev container.** `tool/bakeagent_run.sh` runs
   `docker build -f .devcontainer/Dockerfile .devcontainer` and then the task
   in that image with the checkout mounted at `/workspace`. Inside,
   `tool/bakeagent_container.sh`:
   - installs the pinned, checksum-verified OpenCode CLI from
     `tool/install_opencode_cli.sh` into `/usr/local/bin`, because the image's
     own installer always fetches the newest build;
   - `flutter pub get` for the app and every package;
   - warms the provider catalog up, then `opencode run --standalone` with the
     model from `opencode.jsonc` (`opencode/deepseek-v4.1-flash-free`);
   - `flutter analyze --no-fatal-infos --fatal-warnings` and `flutter test`;
     when the gate fails the agent gets two more passes with the failure log,
     and the run fails if the gate still fails.
   After the container exits, the script hands the workspace back to the
   runner user, because the image has no `remoteUser` and writes as root.
6. **Publish.** When the gate passed and the working tree changed, the
   workflow commits, pushes `bakeagent/<slug>` and opens the PR (base = the
   dispatched branch) with `Bakehub-Task-Id: <id>` in the body.
7. **Clear the feedback.** A feedback task is only cleared after its fix was
   published, so a failed run keeps it for the next attempt.

The pull request then goes through the normal CI and the review
(`call-bob`, see [opencode-review-bob.md](opencode-review-bob.md)).

### Configuration

| Name | Kind | Purpose |
| --- | --- | --- |
| `BAKEHUB_API_KEY` | repository secret | Bakehub API key (`x-api-key`). Without it a run needs the manual inputs. |
| `BAKEHUB_API_URL` | repository variable | Optional endpoint override. Defaults to the project endpoint baked into `tool/bakehub_tasks.py`. |

The key is only used by the host steps that talk to the API; it is never
exported to the container.

### Failure behaviour

| Condition | Result |
| --- | --- |
| No pending task and no manual input | Job succeeds with a notice; nothing is pushed |
| No API key and no manual title | Job fails with a clear message |
| Task already has an open PR (pending task) | Job succeeds with a notice; the task waits for a human |
| Image build fails | Job fails before the agent runs |
| Agent fails | Job fails, no commit, no PR; a feedback task keeps its feedback |
| Free model out of quota (`provider.quota`, 429) | Job fails and names the model; nothing half-finished is published |
| Gate (`analyze` + `test`) still red after two fix passes | Job fails, nothing is pushed |
| Gate green but no file changed | Job succeeds with a notice; nothing is pushed |
| Push or PR creation fails | Job fails; the branch stays local to the runner |

## Running it locally

The image is the same one the dev container builds, so a local run and a CI
run see the same Flutter, OpenCode and tooling versions:

```bash
# Prepare the task exactly like the workflow does.
mkdir -p .bakeagent
python3 tool/bakehub_tasks.py manual --title "Fix the login crash" \
  --description "It crashes on iOS" --output .bakeagent/task.json
python3 tool/bakehub_tasks.py prompt --task .bakeagent/task.json > .bakeagent/prompt.txt

# Build the dev container image and run the task in it.
bash tool/bakeagent_run.sh
git diff   # review, then commit/push yourself
```

The container runs `flutter pub get` for Linux, so it rewrites the local
`.dart_tool/package_config.json`. After a local run, restore the macOS view
before you analyze or test:

```bash
fvm flutter pub get
```

The interactive dev container flow is unchanged: opening the repository in a
dev container or Codespace still runs `.devcontainer/bakehub-setup.sh` from
`postStartCommand`, exactly as before this workflow existed.

`.bakeagent/` (task + prompt + logs) is gitignored and is scratch space only.
