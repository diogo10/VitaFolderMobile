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
| `434603cf73ebf10509a461e683d20c9a` | NON_FATAL — `PlatformException(invalid_icon, The resource ic_notification could not be found)` | **Two causes.** 1.0.0–1.0.3 passed the qualified name `@drawable/ic_notification`. After that was fixed to the bare name, release builds still failed: Flutter's Gradle plugin enables R8 **resource shrinking** for release app builds, so a drawable referenced only by name from Dart is stripped and `Resources.getIdentifier` returns 0 | Bare name in `AndroidInitializationSettings('ic_notification')` **plus** `tools:keep="@drawable/ic_notification"` in `android/app/src/main/res/raw/keep.xml` (shipped in 1.0.6). Drawable: `android/app/src/main/res/drawable/ic_notification.xml`. Guard: `test/android_manifest_test.dart` |
| `8dc90b97c8668cb25938af9a48712556` | FATAL — `PostgrestException(code: 504, details: Gateway Timeout)` | `PeopleRepositoryImpl.getProfilesWithRoleForFamily` throws on a backend/transport failure. The exception escaped `Either.fold`'s **async callback** in `GetReminderUsecase` (and `GetNotesUsecase`), so it surfaced as an unhandled async error instead of a `Failure` | Both usecases wrap the people lookup in `try/catch` and return `Left(Failure(...))`; the screen shows its error state. Guards: `reminders/test/domain/usecase/reminder_usecases_test.dart`, `notes/test/domain/usecase/notes_usecases_test.dart` ("maps a throwing people lookup to Failure instead of crashing") |
| `6ec637b0792c543c04579492624f4e41` | NON_FATAL — `Bad state: GetIt: Object/factory with name reminderNotificationService and type NotificationSender is not registered` | The service was registered only as `IReminderNotificationService`. GetIt keys registrations by the **exact** requested type, and `/notification-settings` resolves it through the core `NotificationSender` seam, so the first open of that screen threw | The same singleton is registered under both types in `reminder_service_locator.dart`. Guard: `reminders/test/reminder_service_locator_test.dart` |
| `2c097c74167a7390ff12a8526430729d` | NON_FATAL — `type 'Null' is not a subtype of type 'NotificationSettingsCubit'` at `_CreateInheritedProviderState.dispose` | Cascade of `6ec637b0`: the route's `BlocProvider(create:)` threw, so provider disposed a null value | No separate change — fixing the GetIt registration removes it |
| `04df8a6a042f93d2a9590f8d9525e328` | FATAL — `Bad state: Cannot emit new states after calling close` | `SignUpCubit.signInWithGoogle` emitted after the cubit was closed: the user left the sign-up screen while the Google sign-in was still in flight, then the call failed and the `catch` block emitted | Stack: `BlocBase.emit` → `sign_up_cubit.dart:87` → `sign_up_screen.dart:128`. Fixed in 1.0.5: every emit that follows an `await` goes through the cubit's `_emitIfOpen` helper (success path included), applied to `signUp`, `signInWithGoogle` and `signInWithApple`. Guards: `packages/house_mira_login/test/presentation/cubit/sign_up_cubit_test.dart` (behavioural: closes the cubit mid-flight) and `test/cubit_emit_guard_test.dart` (source scan of every route-scoped cubit). Cubit rules: `.agents/references/cubit.md` |
| `978e9b8f2b7a8c57baab4aa495af58d2` | NON_FATAL — `RangeError: Invalid value: Only valid value is 0: -1` | The note editor's list-marker button searched the current line with `text.lastIndexOf('\n', start - 1)`; with the cursor at the very start of the content `start - 1` is `-1` and `lastIndexOf` rejects it | `start <= 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1` in `note_editor_screen.dart`. Guard: `packages/house_mira_notes/test/presentation/notes_view_test.dart` |
| `704f61c6eb6811c4f0de2886c7576e89` | NON_FATAL — `Purchases.getCustomerInfo` → `PlatformException(11, …, Invalid API Key)` | RevenueCat was configured with a key its backend rejects (`readableErrorCode: invalidCredentialsError`). `SubscriptionService.isPro` handled it (fail-closed to free limits) but re-fetched on every call, so each session produced a burst of non-fatals for a build-configuration mistake | `SubscriptionService` now disables billing for the session on `unrecoverableBillingErrorCodes` (`isBillingAvailable`), logs one breadcrumb *without* the error object (the error object is what creates the non-fatal) and short-circuits `isPro`/`getOfferingPrices`. Guards: `core/test/subscriptions/subscription_service_test.dart` ("disables billing for the session…", "a rejected key is logged once and never reported as a crash"). The bad key itself lives in the release `--dart-define`, not in the repo |
| `fd17dfd53925250194afe280107f30ac` | NON_FATAL — `FunctionsClient.invoke` → 502 `resend_failed`, "The vitafolder.com domain is not verified" | `resend-email-v1` was sending from an unverified Resend domain, so every invite email failed. The function's `from` is now `contact@contact.housemira.com`; the sender domain still has to stay verified in Resend (ops, not code) | `InvitePeopleCubit` maps *any* edge-function throw to the localized `sendFailed` code instead of putting `e.toString()` (the raw `FunctionException`) in the UI; `EdgetFunctions` keeps the stack trace for Crashlytics. Guard: `people/test/presentation/cubit/invite_people_cubit_test.dart` ("emits sendFailed instead of the raw exception") |
| `3c1cb4b7c40d879044ab355cac0eef38` / `e4bf08e50a22c208c5cca9d64c44d795` | NON_FATAL — `RenderFlex children have non-zero flex but incoming height constraints are unbounded` and its follow-up `RenderBox was not laid out` | One layout exception pair from a single device on 1.0.0, inside a `Column` nested in a `Column` in a `Padding` inside a `Material` with an ink renderer (a card/button chip). The reported trace belongs to the pre-monorepo layout (`package:house_mira/features/…`) | No code change: the frame paths no longer exist in the repo, no `lib/` `Column` puts a flex child in an unbounded height, and the issue never reported on 1.0.1+. Not reproducible; needs a fresh event from a current build before touching layout code |

The `04df8a6a` (emit after close) class shipped in 1.0.5 and stopped reporting.
The notification-icon issue (`434603cf`) did **not** end with the bare-name fix:
Crashlytics still reported it on 1.0.5 (6) with the bare name, because release
resource shrinking strips the drawable. `res/raw/keep.xml` is the missing half
and ships in 1.0.6.

`8dc90b97`, `6ec637b0` and `2c097c74` are 1.0.5-era issues found on 2026-10-22;
their fixes ship in 1.0.6 too, so re-check `lastSeenVersion` before touching
them again. `2c097c74` is a cascade, not an independent bug.

## Sweep 2026-10-24 (10 open issues, 90-day window)

Current build: `1.0.6+7`, not in the field yet — no issue reported on 1.0.6.

| Issue | Events / users | Last seen | Status |
| --- | --- | --- | --- |
| `434603cf` notification icon | 24 / 16 | 1.0.5 | Stale: `res/raw/keep.xml` fix in 1.0.6 |
| `4bbabc28` notification icon | 7 / 3 | 1.0.0 | Stale: same fix |
| `704f61c6` RevenueCat credentials | 2 / 1 | 1.0.0 | Fixed here: billing disabled after a rejected key, no non-fatal |
| `8dc90b97` Postgrest 504 | 2 / 1 | 1.0.5 | Stale: usecases return `Failure` (7ae0c5f), ships in 1.0.6 |
| `fd17dfd5` Resend 502 | 2 / 1 | 1.0.0 | Sender domain moved to `housemira.com`; localized client error added here |
| `2c097c74` provider null cast | 1 / 1 | 1.0.5 | Stale: cascade of `6ec637b0`, fixed by 99dd93d |
| `3c1cb4b7` RenderFlex unbounded | 1 / 1 | 1.0.0 | Stale: pre-monorepo frame paths, not reproducible |
| `6ec637b0` GetIt `NotificationSender` | 1 / 1 | 1.0.5 | Stale: registered under both types (99dd93d) |
| `978e9b8f` note-editor `RangeError` | 1 / 1 | 1.0.0 | Stale: `start <= 0` guard in `note_editor_screen.dart` |
| `e4bf08e5` `RenderBox was not laid out` | 1 / 1 | 1.0.0 | Stale: same layout exception as `3c1cb4b7` |

Re-check every row after 1.0.6 reaches the field: issues fixed in 1.0.6 stay
open until the fixed build is the one crashing, and closing them is a manual
step in the Firebase console (`crashlytics_update_issue` is not exposed to
the agent).

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
