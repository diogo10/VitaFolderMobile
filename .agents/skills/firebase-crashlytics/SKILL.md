---
name: Firebase Crashlytics
description: Triage and fix open Firebase Crashlytics issues for the HouseMira app. Use when asked to "review the Firebase crashes", fix or investigate open crashes, analyse FATAL/NON_FATAL/ANR issues, pull real crash data or stack traces from Firebase, or check which crash is hurting users the most.
---

# Firebase Crashlytics

Turn open Crashlytics issues into merged fixes, using the `firebase` MCP
server. Project `diogoprojects-617e2`, Android app
`1:140355243144:android:a6ac1f14183172f272633d`.

## Preflight (once per session)

1. `firebase_get_environment` — confirms the MCP server found `firebase.json`.
   An active project is **not** required for Crashlytics calls.
2. If a call answers *"The user is not currently logged into the Firebase
   CLI"*, the ADC file is missing. Fix (no restart needed — the MCP server
   re-reads ADC on every call):

   ```bash
   cp ~/.config/gcloud/firebase-crashlytics-sa.json \
      ~/.config/gcloud/application_default_credentials.json
   chmod 600 ~/.config/gcloud/application_default_credentials.json
   ```

3. `firebase_get_project` / `firebase_list_apps` need `.firebaserc` in the
   repo root (`{"projects":{"default":"diogoprojects-617e2"}}`). A
   *"PRECONDITION_FAILED … requires an active project"* answer means that
   file is missing.

Never print, copy, or commit the service-account key.

## Workflow

1. **List the open issues.** `crashlytics_get_report` with
   `report: "topIssues"`, `pageSize: 10`. Keep only issues with
   `state: OPEN`. The default window is the last 7 days — for a full sweep
   use `filter.intervalStartTime` / `filter.intervalEndTime` over the last
   90 days (the API maximum), otherwise issues that stopped occurring after
   their fix stay invisible. The 7-day window is enough to answer "what is
   hurting users right now".

2. **Rank them.** Order by `eventsCount`, then `impactedUsersCount`. Note
   `errorType` (FATAL > ANR > NON_FATAL for urgency), `signals`
   (`SIGNAL_FRESH`, `SIGNAL_REGRESSED`, `SIGNAL_REPETITIVE`) and
   `firstSeenVersion` / `lastSeenVersion`.

3. **Decide if the issue is still live** (see *Stale vs live* below). Skip
   the code change when the fix already shipped.

4. **Get the real stack trace.** For every issue you intend to work on,
   call `crashlytics_batch_get_events` with the issue's `sampleEvent`
   resource name. The issue `subtitle` is a one-line summary; the stack
   trace, `blameFrame`, `device`, `version` and `breadcrumbs` live in the
   event. `crashlytics_list_events` cannot list free-form events — it
   needs `filter.issueId` or `filter.issueVariantId`.

5. **Map the trace to the repo.** The `package:house_mira_<feature>/…`
   path in the frame is `packages/house_mira_<feature>/lib/…`. Open the
   file at the `blameFrame` line and read the surrounding code before
   theorising. Check `references/triage.md` for crash classes this app has
   already seen.

6. **Fix the root cause, with tests.** Follow `AGENTS.md`: feature-first
   packages, one Cubit per concern, sealed states, `AppLocalizations` for
   user-visible text, no hardcoded strings, no faked data on parse
   failures. New code ships with tests (cubit state sequences, use-case
   branches, widget wiring) in the owning package's `test/` directory.

   For the "emit into a closed cubit" class: every emit that can run after
   an `await` goes through the cubit's `_emitIfOpen` helper. The repo-wide
   guard `test/cubit_emit_guard_test.dart` scans every route-scoped cubit
   for a direct `emit(` after an `await` — keep it green when you touch
   one of those cubits, and add a behavioural test (close the cubit
   mid-flight, then assert the pending future completes without throwing).

7. **Verify** in the order given by `AGENTS.md`:

   ```bash
   fvm flutter analyze        # expect: No issues found!
   fvm flutter test           # expect: All tests passed!
   melos test                 # only when business logic changed
   python3 tool/check_business_logic_coverage.py
   python3 tool/check_feature_boundaries.py
   ```

8. **Record it.** `crashlytics_create_note` with the `issueId`, stating the
   cause, what changed, the files touched, and the release the fix ships
   in. Example:

   > Root cause: notification icon passed as `@drawable/ic_notification`;
   > the plugin resolves bare drawable names only. Changed to
   > `AndroidInitializationSettings('ic_notification')` in
   > `reminder_notification_service.dart`; guard test added in
   > `test/android_manifest_test.dart`. Fix ships in 1.0.4.

   The service account needs a role that includes
   `firebasecrashlytics.notes.create` — `roles/firebase.crashlytics.viewer`
   is read-only and answers `403 PERMISSION_DENIED`. When the note fails,
   print the note text for the user instead of retrying.

9. **Report back.** A table: issue id, title, error type, impact, status
   (fixed / stale / needs user), and the verification result.

## Stale vs live

Crashlytics aggregates by app version, so an issue stays open while **old
released versions** still crash on it. Before changing code, compare the
issue's `lastSeenVersion` with the current version in `pubspec.yaml`:

- `lastSeenVersion` **older** than the current version and the fix is
  already in the repo → the issue is **stale**. Do not rewrite code. Note
  the issue with `crashlytics_create_note` and tell the user it can be
  closed in the Firebase console once the fixed build is in the field.
- `lastSeenVersion` **equals** the current version → still live, fix it.
- No fix in the repo → live, fix it.

`crashlytics_update_issue` is not exposed and is denied by
`permissions` in `opencode.jsonc`, so the agent **cannot** close or mute an
issue. Say so explicitly and hand the closing back to the user.

## Guardrails

- Read-only by default: the MCP tool allow-list has no deploy, no
  `firebase_update_environment`, no `crashlytics_update_issue`.
- The service account's `roles/firebase.crashlytics.viewer` covers reads
  only. `crashlytics_create_note` needs
  `firebasecrashlytics.notes.create` (e.g.
  `roles/firebase.crashlytics.admin`); without it the call answers
  `403 PERMISSION_DENIED`. Print the note text for the user instead of
  retrying.
- Never print or commit the service-account key; it stays in
  `~/.config/gcloud/`.
- Commit, push, or open a PR only when explicitly asked.
- iOS report calls answer `404 Requested entity was not found` — there is
  no iOS Crashlytics data yet. That is a data gap, not an auth failure.
- Do not "fix" a crash by swallowing it. A missing asset, an invalid
  argument, or a lifecycle bug must be fixed at the source.
- If the same crash keeps coming back after a fix, check the
  `blameFrame` again — the stack may point at a wrapper rather than the
  real culprit.

## References

- `references/triage.md` — report fields, recurring crash classes in this
  app, and their guard tests.
- `README.md` → "Crashlytics MCP server" — MCP setup and auth.
