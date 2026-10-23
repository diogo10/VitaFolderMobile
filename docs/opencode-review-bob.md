# Automated PR review (`opencode-review-bob`)

How the automated OpenCode review works, what each step trusts, and what
happens when something fails. The workflow lives in
[`.github/workflows/opencode-review-bob.yml`](../.github/workflows/opencode-review-bob.yml);
the merge decision lives in
[`tool/review_merge_gate.py`](../tool/review_merge_gate.py).

## At a glance

| | |
| --- | --- |
| Workflow | `.github/workflows/opencode-review-bob.yml` |
| Caller | `call-bob` job of [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) (`workflow_call`), or a manual `workflow_dispatch` with a `pr` input |
| Model | `opencode/minimax-m3.1-flash-free` (fixed, free, no API key) |
| Timeout | 30 minutes |
| Concurrency | `opencode-review-bob-<pr><event-pr><ref>`, superseded runs cancelled |
| Permissions | `contents: read` by default; the job adds `contents`, `pull-requests`, `issues` and `statuses` write |
| Verdict storage | `opencode-review-grade` commit status on the PR head commit |

## When it runs

`ci.yml` calls the workflow from the `call-bob` job once `analyze-and-test`
has passed:

```yaml
call-bob:
  needs: [analyze-and-test]
  uses: ./.github/workflows/opencode-review-bob.yml
```

Because the caller passes no `pr` input, the workflow falls back to
`github.event.pull_request.number`. A manual run passes the number
explicitly:

```bash
gh workflow run opencode-review-bob.yml -f pr=57
```

A manual run may target a PR on another branch; the review step then runs
`gh pr checkout <pr>` so the working tree and the diff describe that PR.

## Pipeline

The job has two inputs it resolves up front and two outputs it hands
forward: `pr_number` and `base_branch` from the first step, then
`reviewed_sha` and `grade` from the review step.

### 1. Checkout

`actions/checkout` fetches the PR merge ref at depth 1 and does not persist
credentials. On `pull_request` events the checkout therefore holds
`refs/remotes/pull/<n>/merge`, not the PR branch: `HEAD` is the merge
commit. The head commit used by the merge gate is read from the API
instead (`headRefOid`).

### 2. Resolve the pull request to review

- Rejects an `inputs.pr` that conflicts with the event PR, a missing PR
  number, and a non-numeric PR number.
- Resolves the base branch from `gh pr view --json baseRefName`, falling
  back to the repository default branch.
- Fetches the base branch into its **remote-tracking ref**:

  ```bash
  git fetch origin "+refs/heads/$BASE:refs/remotes/origin/$BASE" --depth=50
  ```

  The explicit destination is required. The checkout only fetches the
  merge ref, and `git fetch origin <branch>` writes `FETCH_HEAD` without
  creating `refs/remotes/origin/<branch>` — so without it `origin/<base>`
  does not exist in the job and every trusted-helper read below fails
  with `invalid object name 'origin/<base>'`, which looks exactly like a
  missing file. A failed fetch now fails the step with its own message;
  it is no longer swallowed.

### 3. Resolve the trusted merge gate

Reads `tool/review_merge_gate.py` from `origin/<base>` into
`/tmp/review_merge_gate.py`. The copy on the base branch is used — never
the working-tree copy the pull request controls. When it cannot be read,
the job **fails closed** and no review runs.

### 4. Fail closed: drop a stale `automerge` label

Runs `review_merge_gate.py prepare --pr <n>` before the model starts:
drops a label left over from an earlier run and records a `neutral`
`GRADE=pending` status on the head commit. If the label cannot be read or
dropped, the job fails closed instead of reviewing a PR that could merge
while the review is still running.

### 5. Install the pinned CLI

- `tool/install_opencode_cli.sh --print-target` prints the platform
  target, pinned version and binary SHA-256.
- The CLI cache key contains all three values, so a cache entry can never
  serve a different binary.
- `tool/install_opencode_cli.sh` downloads the pinned npm tarball,
  verifies its SRI hash and the binary's SHA-256, then installs it.

### 6. Review PR with OpenCode v2

1. Writes a sandbox config to `/tmp/review_opencode_config.json` that
   denies shell, edits, webfetch, websearch, skills, sub-agents, tool
   execution and external directories. `OPENCODE_DISABLE_PROJECT_CONFIG=1`
   stops a PR from injecting MCP servers, agents or permissions through
   `opencode.jsonc`.
2. Strips `GITHUB_TOKEN`/`GH_TOKEN` from every CLI call (`env -u`): the
   model never talks to GitHub.
3. Warms up the provider catalog (`opencode models`) until the fixed model
   is routable, with up to six attempts.
4. Captures `reviewed_sha` from the API, builds the diff
   (`git diff origin/<base>...HEAD`, falling back to `gh pr diff`) and the
   diff stat (falling back to the PR metadata API), and re-checks that the
   head commit did not move while the diff was built.
5. Passes the prompt, the stat and the diff as `-f` attachments rather
   than interpolating the diff into a shell variable or argument.
6. Strips `GRADE:` lines from the diff and the stat before the model sees
   them, and truncates the diff to 100KB on line boundaries.
7. Runs `opencode run --standalone --model ... --format json`, retrying
   up to three times when the model is not routable yet. On failure it
   posts a comment with the runner log and exits 1, so a missing review
   can never look like an approval.
8. Parses the grade from the model's **final message** with
   `tool/parse_review_grade.py`, also taken from `origin/<base>`.

### 7. Publish review and apply the merge gate

Posts the parsed review text as a PR comment (truncated to 60KB on line
boundaries), then runs:

```bash
python3 /tmp/review_merge_gate.py gate \
  --pr <n> --grade <A|B|C|D|empty> --reviewed-sha <sha>
```

## Grades

The review prompt asks for exactly one header line `GRADE: <A|B|C|D>`
followed by `## Summary`, `## Findings` and `## Suggestions`.

| Grade | Prompt meaning | Gate action |
| --- | --- | --- |
| `A` | Excellent, merge-ready as is | Label `automerge`, approve, squash-merge, status `success` |
| `B` | Good, minor nits, needs a human merge | Hold: drop the label, status `neutral` |
| `C` | Needs changes before merge | Hold: drop the label, status `neutral` |
| `D` | Major issues, do not merge | Hold: drop the label, status `neutral` |
| none | Missing or invalid output | Hold: drop the label, status `neutral` |

The parser is strict and fails closed: the grade must be the only
`GRADE:` line, it must sit in the header (within the first three non-empty
lines and before any markdown heading), and the message must contain a
`## Findings` section. A grade echoed from the diff cannot pass.

## The merge gate contract

`tool/review_merge_gate.py` has three commands:

- `prepare --pr <n>` — drop a stale `automerge` label and record
  `GRADE=pending` on the head commit before the review.
- `gate --pr <n> --grade <grade> --reviewed-sha <sha>` — record the grade
  and apply the decision. Only grade `A` is merge-ready. The grade is
  recorded on `--reviewed-sha`; if the head commit moved, nothing is
  recorded, the label is dropped and the command exits 1, so the grade of
  the previous commit can never merge a new one.
- `enforce` — used by `.github/workflows/automerge.yml`: list open PRs
  labelled `automerge`, read the `opencode-review-grade` status of each
  head commit, and drop the label from every PR that is not a recorded
  successful grade `A`.

Status descriptions:

| Description | State | Meaning |
| --- | --- | --- |
| `GRADE=pending review in progress` | `neutral` | Review started |
| `GRADE=A merge-ready` | `success` | Grade A bound to this commit |
| `GRADE=<B/C/D/none> needs a human merge` | `neutral` | Not merge-ready |

Exit codes: `0` the gate ran, `1` the gate could not be applied (nothing
was merged), `2` invalid command line.

## Trust model

- **Trusted helpers come from the base branch.** Both
  `parse_review_grade.py` and `review_merge_gate.py` are read from
  `origin/<base>` at run time, so a PR cannot change the rules it is
  graded and merged by. A change to a helper only takes effect for the
  PRs that follow it.
- **The agent is sandboxed** and never receives the GitHub token; only the
  workflow talks to GitHub.
- **Grade lines in the diff are stripped** before the model sees the diff.
- **Residual risk:** for `pull_request` events the workflow file itself
  comes from the PR, so a PR can still change the rules of its own review
  job. Restrict auto-merge to trusted branches or require a human approval
  if that is not acceptable.

### Bootstrapping the helpers

Because the helpers must already exist on the base branch, the PR that
introduces `tool/review_merge_gate.py` cannot be reviewed by it: the
"Resolve the trusted merge gate" step fails closed, and that PR has to be
merged by a human. Once the helper is on `main`, later PRs read it from
there. The same applies to the auto-merge workflow, which refuses to merge
anything while the helper is missing.

## Failure behaviour

| Condition | Result |
| --- | --- |
| PR number missing, ambiguous or non-numeric | Job fails; nothing reviewed or merged |
| Base branch cannot be fetched | Job fails closed |
| Merge gate or grade parser unreadable from base | Job fails closed |
| Stale `automerge` label cannot be dropped | Job fails closed |
| CLI download or checksum verification fails | Job fails |
| Model run fails | Failure comment with the log, job fails |
| No valid grade parsed | Review comment is posted, grade is empty, PR is held |
| Head commit moved during the review | Grade not recorded, label dropped, job fails; the re-review decides |
| Grade `A` but the merge fails | Job fails, nothing is silently left merge-ready |
| `automerge` workflow finds no gate on base | It refuses to merge anything (no PR is merged) |

## Debugging locally

```bash
# Run the merge-gate and parser test suites (also run by CI).
python3 -m unittest tool.test_review_merge_gate -v
python3 -m unittest tool.test_parse_review_grade -v

# Exercise the gate by hand.
python3 tool/review_merge_gate.py prepare --pr 57
python3 tool/review_merge_gate.py gate --pr 57 --grade A --reviewed-sha <sha>
python3 tool/review_merge_gate.py enforce
```

Useful log lines: `Base branch: …` and `Using the merge gate from …`
(which copy was loaded), `Reviewed commit: …` (the commit the grade is
bound to), `Parsed grade: …`, and `decision=merge|hold` from the gate.

## Related files

- `.github/workflows/opencode-review-bob.yml` — the review pipeline.
- `.github/workflows/automerge.yml` — label-driven merge that re-checks
  the recorded grade.
- `tool/review_merge_gate.py`, `tool/test_review_merge_gate.py` — merge
  decision.
- `tool/parse_review_grade.py`, `tool/test_parse_review_grade.py` — grade
  parser.
- `tool/install_opencode_cli.sh` — pinned, checksum-verified CLI install.
- `README.md` → "Automated PR review (Bob)".
