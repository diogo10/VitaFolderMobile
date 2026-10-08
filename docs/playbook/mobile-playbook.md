# Company-Wide Mobile Playbook

How we build Flutter screens at HouseMira. Normative for all mobile
work; ADRs in `../adr/` record the underlying decisions. If this file
and an ADR disagree, the ADR wins and this file must be fixed.

Sources: `AGENTS.md`, `.agents/references/cubit.md`,
`.agents/references/architecture.md`, `.agents/references/testing.md`.

## 1. State management — Cubit sealed-state "Loading-to-outcome"

`flutter_bloc` Cubits only. No Provider, no raw `setState` for shared
state. One Cubit per presentation concern in
`lib/features/<feature>/presentation/cubit/`.

### 1.1 States

Sealed hierarchy, one `*_state.dart` file per cubit:

```dart
sealed class AccountState { AccountState(); }
class AccountInitial extends AccountState { AccountInitial(); }
class AccountLoading extends AccountState { AccountLoading(); }
class AccountLoaded extends AccountState { /* final display-ready fields */ }
class NoAccount extends AccountState { NoAccount(); }
class LoginFailed extends AccountState { LoginFailed(); }
```

Rules:

- Success states carry `final`, display-ready fields.
- One distinct failure state per case the UI must distinguish
  (e.g. `AccountDeleteFailed(code:)` with a typed error-code enum).
- Annotate `@immutable` when overriding `==`/`hashCode`.
- Real example: `lib/features/account/presentation/cubit/account_state.dart`.

### 1.2 Cubit methods

- One `async` method per user intent (`signIn`, `loadAccount`,
  `deleteAccount`, …).
- Emit `Loading` first, then **exactly one** outcome state.
- Translate service exceptions to states; never leak `AuthException` /
  Supabase errors to widgets.
- Cancelled flows (e.g. Google sign-in returns `null`) emit the neutral
  state (`NoAccount`), not a failure.
- Delegate side effects to injected services (`AuthService`,
  repositories, use cases). Real example:
  `lib/features/account/presentation/cubit/account_cubit.dart`.

### 1.3 Views

- `BlocBuilder` for rendering, `BlocConsumer` when reacting (navigation,
  dialogs). Trigger with `context.read<Cubit>().method()`.
- Render loading UI from `*Loading` states (pass `isLoading` into
  buttons).
- Keep widgets small: extract `*_widget.dart` files per section.
- All user-visible strings via `AppLocalizations`
  ([ADR-0005](../adr/0005-localization-l10n-only.md)).

## 2. Architectural boundaries — no Supabase in Cubits

```
presentation/cubit  →  application/ + domain/  →  data/ (Supabase lives here)
```

- Supabase imports (`supabase_flutter`, `SupabaseClient`) are allowed
  only in `data/` repositories/datasources, `lib/core/auth/`,
  `lib/core/functions/`, and DI wiring. **Never in a cubit.**
- Cubits depend on injected services/repositories/use cases via
  constructors; composition happens in
  `lib/core/injections/<feature>/*_service_locator.dart` and the router
  factories ([ADR-0002](../adr/0002-dependency-injection-getit.md)).
- Error translation happens twice, at fixed layers: SDK errors →
  `Failure` in repositories ([ADR-0003](../adr/0003-error-handling-either-failure.md));
  `Failure`/exceptions → states in cubits. Widgets only see states.
- Spot-check: `grep -r "supabase" lib/features/<feature>/presentation/cubit/`
  must return nothing but comments.

## 3. Concurrency — async and `unawaited` conventions

From `AGENTS.md`; `dart:async` `unawaited` marks intentional
fire-and-forget so the `unawaited_futures` lint stays clean.

- `await` every Future inside `async` functions. No floating futures.
- Sync callbacks that must trigger async work (button handlers,
  `initState`, stream listeners, `TabRefreshCoordinator` closures, `close()`)
  either become `async` with `await`, or wrap the call in `unawaited()`
  with `import 'dart:async'`.
- `unawaited` is **only** for fire-and-forget: refresh-after-event,
  subscription cancel in `close()`, best-effort reloads. Never use it to
  hide a result the UI or the next line depends on.
- Catch with `on Object catch (e, stackTrace)` (log + map to state).
  Never a bare `catch`, never narrow-and-swallow.
- Tests: `await` everything in setup/assertions; `unawaited()` only for
  intentionally fire-and-forget calls.

```dart
// Sync callback → fire-and-forget refresh.
onPressed: () => unawaited(context.read<PeopleCubit>().getPeople()),

// Inside close(): best-effort cancel.
@override
Future<void> close() {
  unawaited(_authSubscription?.cancel());
  return super.close();
}
```

Real examples: `AccountCubit._onSignedInChanged` / `close()`,
`TabRefreshCoordinator` closures in `lib/core/router/app_router.dart`.

## 4. Testing expectations (summary)

Full rules: `.agents/references/testing.md`.

- New cubit method → `bloc_test` state-sequence tests incl. cancel +
  failure paths.
- New use case / entity branch / service line → unit test (CI enforces
  100% line coverage per file under every `domain/` and `application/`
  dir via `tool/check_business_logic_coverage.py`).
- New button/callback wiring → widget test tapping it.
- Bug fix → regression test reproducing it first.
- Fakes by subclassing mockable classes; mocktail for Supabase clients
  and platform plugins; throw only `Exception`/`Error` in fakes.

## 5. Mentor-friendly onboarding

Use this playbook as the week-one spine; each item ends with something
to read, do, and show.

1. **Read the layers** (30 min): `AGENTS.md` →
   `.agents/references/architecture.md` → browse one feature end to end
   (`people`: cubit → use case → repository impl).
   *Show:* draw the layer diagram for that feature from memory.
2. **Emit your first state machine** (half day): read
   `account_cubit.dart` + `account_state.dart` and its `bloc_test` suite.
   *Do:* add a trivial cubit method behind a flag, with Loading→outcome
   states and sequence tests. *Show:* tests green, coverage gate green.
3. **Cross one boundary correctly** (half day): read ADR-0002/0003 and
   `people_service_locator.dart`. *Do:* wire a fake repository through
   DI in a test without touching GetIt. *Show:* explain why the cubit
   has no Supabase import.
4. **Ship a reviewed slice** (rest of week): pick a small UI string
   change or empty-state. Follow ADR-0005 (both ARBs), the checklist in
   `../code-review-checklist.md`, then `fvm flutter analyze` +
   `fvm flutter test`. *Show:* a PR the checklist passes on first read.

Mentor prompts for each review: "Which state did Loading resolve to?",
"Where did the Supabase error become a Failure, and where did the
Failure become a state?", "What happens on cancel?", "Where is the
Portuguese string?"
