# Implementation Plan: 001-notes — Shared Family Notes

**Branch**: `001-notes` | **Date**: 2026-09-30 | **Spec**: [specs/001-notes/spec.md](spec.md)

## Summary

Implement shared, color-coded family Notes (CRUD, `created_at DESC`, pull-to-refresh, hard delete with confirm, rich-text bold/lists) following the reminders feature pattern: `lib/features/notes/{domain,data,presentation}` + `NotesCubit` + `Either<Failure,T>` repository + Supabase `notes` table with `family_memberships`-based RLS + Notes bottom-nav tab between People and Reminders + EN/PT ARB keys. No local cache, no search/filter, last-write-wins, `created_by` audit-only.

## Technical Context

**Language/Version**: Dart / Flutter 3.41.6 via FVM (`.fvmrc`; all commands `fvm`-prefixed)
**Primary Dependencies**: `flutter_bloc` (Cubits), `get_it` (`lib/core/injections/service_locator.dart`), `go_router`, `supabase_flutter`, `fpdart` (`Either<Failure, T>`)
**Storage**: Supabase `notes` table (new, in `sqls/notes_schema.sql`): `id uuid PK DEFAULT gen_random_uuid()`, `family_id uuid NOT NULL REFERENCES families(id) ON DELETE CASCADE`, `created_by uuid NOT NULL DEFAULT auth.uid()`, `title/content/color text NOT NULL`, `created_at/updated_at timestamptz NOT NULL DEFAULT now()` + `updated_at` trigger; `CHECK (color IN ('yellow','pink','blue','green','orange'))`; `CHECK (char_length(trim(title)) BETWEEN 1 AND 100 AND char_length(trim(content)) BETWEEN 1 AND 300)`; RLS `USING/WITH CHECK (EXISTS (... family_memberships ...))` mirroring `reminders` policies in `sqls/database_schema.sql`. Data access in `lib/features/notes/data/` (injected `SupabaseClient`, mapped to `Failure` at boundary).
**Testing**: `fvm flutter test` (+ scoped `fvm flutter test test/features/notes`); coverage `fvm flutter test --coverage` + `python3 tool/check_business_logic_coverage.py` (100% per file under `lib/**/domain/`, `lib/**/application/`); secrets `bash tool/check_no_hardcoded_secrets.sh`
**Target Platform**: iOS / Android
**Lint**: `very_good_analysis` (`public_member_api_docs` off); verify `fvm flutter analyze` → `No issues found!`
**Config/Secrets**: `AppConfig.fromEnvironment` (`APP_FLAVOR`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`); local run `fvm flutter run --dart-define-from-file=env/dev.json`; never hardcode keys/URLs/service_role in `lib/`
**Localization**: AppLocalizations via `lib/l10n/app_en.arb` + `lib/l10n/app_pt.arb` — new keys: `navNotes`, `notesTitle`, `notesEmptyTitle/Message`, `notesUnauthenticatedTitle/Message`, `notesTitleRequired/TooLong`, `notesContentRequired/TooLong`, `notesDeleteDialogTitle/Message/Confirm/Cancel`, `notesCreateTitle/EditTitle`, `notesSave`, `notesError*`
**Navigation**: `go_router` only — insert Notes `StatefulShellBranch` (`/notes`) between the People and Reminders branches (existing indices after it shift by one; deep links/tests updated accordingly) with shared `NotesCubit` lazy-singleton factory + one-shot create/edit route (`/notes/edit`) with fresh cubit or same cubit method; `MainShell` gains `Icons.note_rounded` tab between People and Reminders; follow `createRouter` factory contract (tab shared via `BlocProvider.value`, one-shot fresh via `BlocProvider(create:)`)
**Rich-text (FR-109)**: content stored as plain `text` (lightweight markdown subset: `**bold**`, `- list` lines); render with `Text.rich`/custom parser in view, edit with plain `TextField` + exactly two toolbar buttons (bold, list) inserting markers. No new dependency (`flutter_quill` rejected — heavy, Delta JSON breaks 300-char `CHECK` semantics and ARB/size expectations). 300-char limit counts raw stored string including markers (documented in quickstart).
**Bottom sheet & acceptance (SC-009/SC-102)**: tap note → bottom sheet with Edit + Remove only (follows reminders bottom-sheet design); edit form reuses create design as-is; acceptance is reviewer sign-off per asset.
**Locale layout (FR-110)**: screens render overflow-free in EN + PT (~30% PT expansion); long titles/bodies wrap/ellipsize; widget tests pump both locales with no `RenderFlex` overflow.
**Family scope**: resolve `familyId` via `PeopleRepository.getFamilyIdsForUser(authService.currentUserId)` (same as `RemindersCubit._resolveFamilyId`); unauthenticated (`currentUserId == null`) → `NotesUnauthenticated`; RLS denial → `NotesFailure` localized.
**Ordering**: `created_at DESC` only (`order('created_at', ascending: false)`); no search/filter/sort UI.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*
See `.specify/memory/constitution.md` (mirrors `AGENTS.md`).

- [x] Feature-first paths identified (`lib/features/notes/{domain,data,presentation}` + `lib/core/` shared); DI via `lib/core/injections/notes/notes_service_locator.dart` aggregated in `lib/core/injections/service_locator.dart`. No `application/` layer (no cross-repo orchestration; cubit calls use-cases directly like reminders list flow — notification service pattern not needed).
- [x] Cubit design: sealed states (`NotesInitial`, `NotesLoading` first then exactly one outcome, `NotesUnauthenticated`, `NotesLoaded`, `NoteActionSuccess` transient, `NotesFailure`), services constructor-injected, no Supabase imports in `presentation/cubit/`
- [x] Error design: `Either<Failure, T>` only at repo boundary; entity `Note.from` null-on-bad-input (no fake-data fallbacks); `on Object` catch mapped to `Failure`
- [x] Localization: ARB keys planned for EN + PT, no hardcoded strings (FR-107)
- [x] Gates planned: analyze / test / 100% business-logic coverage (`domain/` entity+repo-interface+usecases) / no-hardcoded-secrets

## Project Structure

```text
specs/001-notes/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── notes_repository.md
│   └── notes_schema.md
└── tasks.md

lib/features/notes/
├── domain/        # entities/note_entity.dart, entities/note_color.dart, repository/notes_repository.dart, usecase/get_notes_usecase.dart, create_note_usecase.dart, update_note_usecase.dart, delete_note_usecase.dart (filenames mirror class names, cf. reminders precedent)
├── data/          # repository/notes_repository_impl.dart, models/note_model.dart (extends entity, toCreate/toUpdate)
└── presentation/  # cubit/{notes_cubit.dart, notes_state.dart}, views/{notes_view.dart, note_editor_screen.dart}, widgets/{note_card_widget.dart, note_color_picker_widget.dart, notes_empty_widget.dart}

lib/core/injections/notes/notes_service_locator.dart
lib/core/router/ (notes branch between People and Reminders + MainShell tab)
lib/l10n/app_en.arb + app_pt.arb (new notes keys)
sqls/notes_schema.sql (new table + RLS + trigger)
```

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None — no `application/` layer | Notes is single-repo CRUD; cubit orchestrates use-cases directly | An `application/` service would add indirection with no cross-repo logic (unlike reminders notifications) |
| One-shot editor reuses `NotesCubit` methods instead of second cubit | Spec FR-102 mandates all logic in one `NotesCubit` | Separate `CreateNoteCubit` (reminders pattern) would violate FR-102 single-cubit requirement |

## Post-design Constitution Re-check (Phase 1 complete)

- [x] I–VII still hold: FVM toolchain, feature-first paths (`lib/features/notes/`), single `NotesCubit` with sealed states, Supabase-only backend, GetIt per-feature locator, `Either<Failure,T>` + null-on-invalid entity, ARB-only strings, `on Object` catches, `go_router` only.
- [x] No new violations introduced by `research.md` / `data-model.md` / `contracts/` / `quickstart.md` decisions (markdown-subset rich text keeps `CHECK` semantics; `family_memberships` correction aligns with real schema; no new dependencies).
