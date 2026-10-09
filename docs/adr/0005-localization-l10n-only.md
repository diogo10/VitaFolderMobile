# ADR-0005: Localization — l10n-only strings in UI

- Status: Accepted
- Date: 2026-10-08
- Source: `AGENTS.md`, `lib/l10n/`

## Context

The app ships in English and Portuguese (`app_en.arb`, `app_pt.arb`).
Hardcoded user-visible strings bypass translation, break the second
locale silently, and cannot be caught by tests that only run one locale.

## Decision

- All user-visible text comes from `AppLocalizations`, backed by
  `lib/l10n/app_en.arb` (and `lib/l10n/app_pt.arb`). Never hardcode
  user-visible strings in widgets, views, or screens. Pattern:

  ```dart
  final l = AppLocalizations.of(context)!;
  Text(l.navHome);
  ```

  Examples: `lib/features/account/presentation/views/account_view.dart`,
  `lib/features/account/presentation/views/account_no_account_header_widget.dart`.
- Add every new string to **both** ARB files in the same PR (English
  value + Portuguese translation); `l10n.yaml` + `flutter gen-l10n`
  generates the bindings.
- Non-visible strings (route paths, query-param keys, storage keys,
  debug logs) stay as code constants and are out of scope.

## Consequences

- New UI ships with both ARB entries; missing Portuguese is a review
  blocker.
- Widget tests pump with `AppLocalizations.localizationsDelegates` +
  `supportedLocales` (see `.agents/references/testing.md`).
- String changes are ARB diffs, reviewable by non-engineers.

## References

- `lib/l10n/app_en.arb`
- `lib/l10n/app_pt.arb`
- `l10n.yaml`

## Code-review checklist

- [ ] Zero new hardcoded user-visible strings (search the diff for raw
      `Text("…")` / `'...'` literals shown in UI)?
- [ ] New keys added to both `app_en.arb` and `app_pt.arb`?
- [ ] Widget tests provide localization delegates + supported locales?
