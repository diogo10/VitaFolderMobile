# ADR-0001: Routing with go_router and a centralized route table

- Status: Accepted
- Date: 2026-10-08
- Source: `AGENTS.md`, `lib/core/router/`

## Context

Navigation call sites must never scatter raw string paths or unchecked
`state.extra` casts, and deep links (invite links, notification taps)
must resolve to the same locations as in-app navigation. The router also
has to hold navigation on splash during Supabase session recovery, keep
guest browsing working, and avoid constructing unvisited tab cubits on
cold start.

## Decision

- Use `go_router` (`GoRouter`), built by `createRouter` in
  `lib/core/router/app_router.dart`.
- Keep every path, query-param key, and invite-link builder in one place:
  `AppRoutes` plus typed wrappers (`InvitePeopleRoute`,
  `CreateReminderRoute`, `JoinInviteRoute`) in
  `lib/core/router/app_routes.dart`.
- Keep the redirect matrix pure and synchronous in `resolveAppRedirect`
  (splash gate, signed-in-away-from-sign-up, bad-invite-code fallback to
  `/people`) so it is unit-testable without pumping widgets.
- Preserve the pre-auth location in the splash `next` query parameter and
  validate it in `_validatedNext` (reject absolute URLs, splash loops).
- Tab routes use a `StatefulShellRoute.indexedStack` (`MainShell`); tab
  cubits are shared singletons provided via `BlocProvider.value`, one-shot
  screens get a fresh cubit per visit via `BlocProvider(create:)`.
  Cross-tab refresh goes through `TabRefreshCoordinator`, never by pulling
  sibling cubits from views. Notification taps map via
  `notificationLocationFor`.

## Consequences

- New screens add a constant (and typed wrapper when they take args) in
  `app_routes.dart` plus a `GoRoute` in `app_router.dart`; no raw paths
  at call sites.
- Router tests pin the redirect matrix, the shared-vs-fresh cubit factory
  contract, and route-scoped cubit laziness.
- Deep-link and email-CTA changes must keep `AppRoutes.inviteWebBase`,
  `EdgetFunctions` templates, and native App Link declarations in sync.

## References

- `lib/core/router/app_router.dart`
- `lib/core/router/app_routes.dart`
- `lib/core/router/main_shell.dart`
- `lib/core/router/tab_refresh_coordinator.dart`

## Code-review checklist

- [ ] No raw string route path outside `app_routes.dart`?
- [ ] New route args use a typed `*Route` wrapper with null-safe parsing
      (unknown extras ignored, never crashing)?
- [ ] Redirect-matrix change covered by `resolveAppRedirect` unit tests?
- [ ] Shared tab cubit uses `BlocProvider.value`; one-shot screen uses
      `BlocProvider(create:)` with a fresh instance per call?
