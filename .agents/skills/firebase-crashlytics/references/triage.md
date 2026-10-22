# Crashlytics triage reference

## Report and issue fields

`crashlytics_get_report` returns groups of `metrics` plus the `issue`:

| Field | Meaning |
| --- | --- |
| `issue.id` | Hex UUID — the `issueId` for `crashlytics_get_issue`, `crashlytics_list_events`, `crashlytics_create_note` |
| `issue.title` | `package:<file> - <symbol>`: where it crashed |
| `issue.subtitle` | One-line error message (often truncated) |
| `issue.errorType` | `FATAL` (crash), `NON_FATAL` (exception), `ANR` |
| `issue.sampleEvent` | Event resource name — feed it to `crashlytics_batch_get_events` for the stack trace |
| `issue.state` | `OPEN` / `CLOSED` |
| `issue.firstSeenVersion` / `lastSeenVersion` | Version range the issue spans |
| `issue.signals` | `SIGNAL_FRESH` (new), `SIGNAL_REGRESSED` (came back), `SIGNAL_REPETITIVE` (3+ per user) |
| `metrics.eventsCount` | Events in the window |
| `metrics.impactedUsersCount` | Distinct users hit |
| `metrics.crashFreeUsersPercentage` | App-level crash-free users for the window |
| `metrics.totalUsersCount` / `totalSessionsCount` | App totals (not per issue) |

Useful reports: `topIssues`, `topVariants`, `topVersions`, `topOperatingSystems`,
`topAndroidDevices`, `topAppleDevices`, `webMetrics`.

## Event fields worth reading

`crashlytics_batch_get_events` on the `sampleEvent` returns:

| Field | Use |
| --- | --- |
| `exceptions` | The Dart stack trace — `package:house_mira_<feature>/…` maps to `packages/house_mira_<feature>/lib/…` |
| `blameFrame` | `file`, `line`, `symbol` — the frame to open first |
| `version.displayName` | e.g. `1.0.3 (4)` — the build that crashed |
| `device` | Manufacturer/model — device-specific crashes look different here |
| `breadcrumbs` | Session trail before the crash (`session_start`, `screen_view`, …) |
| `logs` | App log lines around the failure |
| `customKeys` | `flutter_error_exception`, `flutter_error_reason` — the raw error |
| `issueVariant.id` | Pass as `filter.issueVariantId` to `crashlytics_list_events` |

## Crash classes this app has already seen

| Issue | Error | Cause | Fix / guard |
| --- | --- | --- | --- |
| `e800d234738fc1a0631258e0794666f9` | FATAL — `GoogleFonts.config.allowRuntimeFetching is false but font Figtree-Regular was not found in the application assets` | The theme resolved the family over the network; release builds disable the download, so the first themed text threw | `google_fonts` removed, families bundled in `assets/fonts/` and declared in `pubspec.yaml`. Guard: `test/theme/font_bundle_test.dart`. Rules: `.agents/references/fonts.md` |
| `434603cf73ebf10509a461e683d20c9a` | NON_FATAL — `PlatformException(invalid_icon, The resource @drawable/ic_notification could not be found)` | The small icon was passed as the qualified Android name `@drawable/ic_notification`; the plugin resolves bare drawable names only, so `initialize()` failed and **no reminder notification was ever shown** | `AndroidInitializationSettings('ic_notification')`. Drawable: `android/app/src/main/res/drawable/ic_notification.xml`. Guard: `test/android_manifest_test.dart` |
| `04df8a6a042f93d2a9590f8d9525e328` | FATAL — `Bad state: Cannot emit new states after calling close` | `SignUpCubit.signInWithGoogle` emitted after the cubit was closed: the user left the sign-up screen while the Google sign-in was still in flight, then the call failed and the `catch` block emitted | Stack: `BlocBase.emit` → `sign_up_cubit.dart:87` → `sign_up_screen.dart:128`. Fixed in 1.0.5: every emit that follows an `await` goes through the cubit's `_emitIfOpen` helper (success path included), applied to `signUp`, `signInWithGoogle` and `signInWithApple`. Guards: `packages/house_mira_login/test/presentation/cubit/sign_up_cubit_test.dart` (behavioural: closes the cubit mid-flight) and `test/cubit_emit_guard_test.dart` (source scan of every route-scoped cubit). Cubit rules: `.agents/references/cubit.md` |
| `978e9b8f2b7a8c57baab4aa495af58d2` | NON_FATAL — `RangeError: Invalid value: Only valid value is 0: -1` | The note editor's list-marker button searched the current line with `text.lastIndexOf('\n', start - 1)`; with the cursor at the very start of the content `start - 1` is `-1` and `lastIndexOf` rejects it | `start <= 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1` in `note_editor_screen.dart`. Guard: `packages/house_mira_notes/test/presentation/notes_view_test.dart` |

The `434603cf` (notification icon) and `04df8a6a` (emit after close) classes
shipped in **1.0.4/1.0.5** while Crashlytics still reports them against
1.0.0–1.0.3. Those issues stay `OPEN` until a fixed build is in the field —
they are stale, not regressions.

## Mapping a frame to the repo

| Frame prefix | Repo path |
| --- | --- |
| `package:house_mira_core/…` | `packages/house_mira_core/lib/…` |
| `package:house_mira_<feature>/…` | `packages/house_mira_<feature>/lib/…` |
| `package:<pub_package>/…` (e.g. `bloc`, `flutter_local_notifications`) | Third-party — read the trace upstream, then find the call site in this repo |
| `.main` | `lib/main.dart` (the composition root) |

## Version awareness

`pubspec.yaml` carries the current version (`version: <x.y.z>+<build>`).
Crashlytics reports `displayName: <version> (<build>)`, so compare the
build number too: a crash seen only in older builds of the same version
predates the latest build's changes.
