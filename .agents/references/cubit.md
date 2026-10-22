# State management (Cubit)

`flutter_bloc` Cubits only — no Provider, no raw `setState` for shared
state. One Cubit per presentation concern: `packages/house_mira_<feature>/lib/presentation/cubit/`.

## States

Sealed class hierarchy, one file `*_state.dart`:

```dart
sealed class AccountState { AccountState(); }
class AccountInitial extends AccountState { AccountInitial(); }
class AccountLoading extends AccountState { AccountLoading(); }
class AccountLoaded extends AccountState { /* final fields */ }
class NoAccount extends AccountState { NoAccount(); }
class LoginFailed extends AccountState { LoginFailed(); }
```

Success states carry `final` display-ready fields; distinct failure states
per case the UI must distinguish (e.g. `AccountDeleteFailed(code:)`).
Annotate `@immutable` when overriding `==`/`hashCode`.

## Cubit methods

- One `async` method per user intent (`signIn`, `signInWithGoogle`,
  `loadAccount`, `deleteAccount`).
- Emit `Loading` first, then exactly one outcome state.
- Translate service exceptions to states; never leak `AuthException`/
  Supabase errors to widgets. Cancelled flows (Google returns `null`)
  emit the neutral state (`NoAccount`), not a failure.
- Delegate side effects to injected services (`AuthService`,
  repositories); cubits hold no Supabase imports.
- **Never emit into a closed cubit.** A route-scoped cubit (the router
  hands it to `BlocProvider(create:)`) is closed as soon as the user
  leaves the screen, and that happens while an async flow is still
  running — the native Google/Apple sheet, a store call, a backend
  request. `Cubit.emit` then throws
  `StateError: Cannot emit new states after calling close`, which reaches
  Crashlytics as a fatal error and the user sees as a crash (FATAL
  Crashlytics issue `04df8a6a`). Every emit that can run after an
  `await` therefore goes through the cubit's `_emitIfOpen` helper, which
  drops the state instead of throwing. Guard:
  `test/cubit_emit_guard_test.dart`.

## Views

- `BlocBuilder` for rendering, `BlocConsumer` when reacting
  (navigation, dialogs). Trigger with `context.read<Cubit>().method()`.
- Show loading UI from `*Loading` states (pass `isLoading` into buttons).
- Keep widgets small: extract `*_widget.dart` files per section.

## Tests

`bloc_test` for state sequences, plain `flutter_test` + fake services
for logic. See `testing.md`.
