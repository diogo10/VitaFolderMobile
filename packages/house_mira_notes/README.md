# house_mira_notes `0.1.0`

Part of the HouseMira Melos workspace. Independently versioned; bump
with `melos version` (conventional commits) — never by hand-editing
dependents.

- Owner: @diogo10/notes-team (see root `.github/CODEOWNERS`)
- Public API: `lib/house_mira_notes.dart` (domain entities, repository contracts,
  use cases). Data implementations and presentation are package-private
  except the feature's `*_service_locator.dart` DI entry point and the
  documented shared surfaces (`family_header_widget.dart`,
  `family_member_card_widget.dart`, `navigation/create_reminder_route.dart`).
- Boundaries: enforced by `tool/check_feature_boundaries.py` (P1–P4) in CI.
  No cross-package `data/` imports; core never imports features;
  feature-to-feature via `domain/` only.

```bash
# selective runs (team ownership, parallel builds)
melos test:notes   # or: cd packages/house_mira_notes && flutter test --coverage
```
