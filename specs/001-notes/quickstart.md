# Quickstart: 001-notes validation

**Spec**: [spec.md](spec.md) | **Contracts**: [contracts/notes_repository.md](contracts/notes_repository.md), [contracts/notes_schema.md](contracts/notes_schema.md)

## Prerequisites

- `fvm flutter pub get`; Supabase dev project with `families` + `family_memberships` seeded and two test users in the same family; run via `fvm flutter run --dart-define-from-file=env/dev.json`.

## Scenarios (manual + test mapping)

1. **Empty list (SC-001)**: sign in as member with no notes → Notes tab shows `notesEmptyTitle/Message`. Tests: `loadNotes` empty → `NotesLoaded([])`.
2. **Unauthenticated (SC-002)**: sign out → Notes tab shows `notesUnauthenticatedTitle/Message` (design `designs/html/01-FamilyAdmin - Notes for Unlogged User.html`). Tests: no `currentUserId` → `NotesUnauthenticated`.
3. **Create (US2)**: tap add → form (design `designs/html/01-FamilyAdmin - Notes (Create).html`) → pick color swatch, enter title ≤100 / body ≤300 (markers `**`/`- ` count), Save → returns to the list with new card in `created_at DESC` position. Over-limit/whitespace-only → localized inline errors, no save. Tests: success → `NoteActionSuccess` + reload `NotesLoaded`; failure → `NotesFailure`.
4. **Pull-to-refresh (SC-008)**: pull list → platform indicator → `NotesLoading` → `NotesLoaded` re-synced (insert a row directly in Supabase first to prove sync). Offline pull → localized `NotesFailure`.
5. **Edit (US3)**: tap note → bottom sheet (Edit + Remove only, per `_ReminderMenuSheet`) → Edit → pre-populated form reusing the create design → save → updated card + `updated_at` bumped. Concurrent edit from second user → last-write-wins, no conflict UI.
6. **Delete (US4)**: sheet → Remove → localized confirm dialog → confirm → row gone (hard delete, no restore). Cancel/dismiss → unchanged list, no failure state.
7. **Offline**: airplane mode → open list or save → localized `NotesFailure`; reconnect + pull-to-refresh → `NotesLoaded`.
8. **Family switch**: change family context → list refreshes to new `family_id` (no cross-family leakage).

## Gates

```bash
fvm flutter analyze
fvm flutter test test/features/notes
fvm flutter test --coverage
python3 tool/check_business_logic_coverage.py
bash tool/check_no_hardcoded_secrets.sh
```

Expect: `No issues found!`, `All tests passed!`, 100% per file under `lib/features/notes/domain/` (no `application/` layer exists), secrets check passes. Visual check is reviewer sign-off per asset (SC-102) against `designs/html/01-FamilyAdmin - Notes.html`, `Notes (Empty).html`, `Notes (Create).html`, `Notes for Unlogged User.html` (PDF exports under `designs/` are not governing). Widget tests pump EN + PT locales with no `RenderFlex` overflow (FR-110).
