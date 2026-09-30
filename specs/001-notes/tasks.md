# Tasks: 001-notes — Shared Family Notes

**Input**: Design documents from `specs/001-notes/` (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md)
**Stack**: Dart / Flutter 3.41.6 via FVM — all commands `fvm`-prefixed

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel
- **[Story]**: User story this task belongs to
- Include the exact file path in every code task (feature-first: `lib/features/notes/{domain,data,presentation}/`, DI in `lib/core/injections/`)

## Phase 1: Setup

- [ ] T001 [P] Create `sqls/notes_schema.sql` per `contracts/notes_schema.md` (table + `CHECK (color IN ('yellow','pink','blue','green','orange'))` + `CHECK (char_length(trim(title)) BETWEEN 1 AND 100 AND char_length(trim(content)) BETWEEN 1 AND 300)` + `family_memberships` RLS + `updated_at` trigger)
- [ ] T002 [P] Create feature skeleton `lib/features/notes/{domain/{entities,repository,usecase},data/{models,repository},presentation/{cubit,views,widgets}}` and empty `lib/core/injections/notes/notes_service_locator.dart` aggregated in `lib/core/injections/service_locator.dart`
- [ ] T003 Apply `sqls/notes_schema.sql` to the dev Supabase project via `supabase db push` (or dashboard SQL editor) and verify a non-member read is denied by RLS

## Phase 2: Foundational

- [ ] T004 Add 24 ARB keys (`navNotes`, `notesTitle`, `notesTitleLabel/Hint`, `notesContentLabel/Hint`, `notesEmptyTitle/Message`, `notesUnauthenticatedTitle/Message`, `notesTitleRequired/TooLong`, `notesContentRequired/TooLong`, `notesCreateTitle`, `notesEditTitle`, `notesSave`, `notesDeleteDialogTitle/Message/Confirm/Cancel`, `notesErrorGeneric/NotFound/Offline`) to `lib/l10n/app_en.arb` + `lib/l10n/app_pt.arb` and run `flutter gen-l10n`

## Phase 3: US1 View Notes List (Priority: P1)

**Goal**: Family members see their notes ordered `created_at DESC` with empty/unauthenticated/error states and pull-to-refresh.
**Independent test**: Sign in → Notes tab shows seeded notes newest-first; empty family → empty state; signed out → unauthenticated state; airplane mode → localized failure; pull → re-sync.

- [ ] T005 [P] [US1] Create `Note` entity in `lib/features/notes/domain/entities/note_entity.dart` plus palette in `lib/features/notes/domain/entities/note_color.dart` (`from` returns `null` on missing/invalid ids, empty-after-trim or `trimmed.length > 100` title / `> 300` content, non-allowlisted color, bad timestamps; `copyWith`, `==`/`hashCode`, `const` constructor)
- [ ] T006 [P] [US1] Create `NotesRepository` interface in `lib/features/notes/domain/repository/notes_repository.dart` (all methods `Future<Either<Failure, T>>` per contracts/notes_repository.md)
- [ ] T007 [US1] Create `NoteModel` in `lib/features/notes/data/models/note_model.dart` (`fromMap`/`toCreate`/`toUpdate`) and `NotesRepositoryImpl` in `lib/features/notes/data/repository/notes_repository_impl.dart` (`.eq('family_id', familyId).order('created_at', ascending: false)`; Supabase errors → `Failure` at boundary, `on Object` catch)
- [ ] T008 [US1] Create `GetNotesUsecase` in `lib/features/notes/domain/usecase/get_notes_usecase.dart`
- [ ] T009 [US1] Create sealed states in `lib/features/notes/presentation/cubit/notes_state.dart` and `NotesCubit.loadNotes` in `lib/features/notes/presentation/cubit/notes_cubit.dart` (`NotesLoading` first then exactly one of `NotesLoaded`/`NotesUnauthenticated`/`NotesFailure`; no Supabase imports)
- [ ] T010 [US1] Create `NotesView` in `lib/features/notes/presentation/views/notes_view.dart` + `note_card_widget.dart` (palette background, `Text.rich` markdown render; titles ellipsize max 2 lines, bodies wrap per FR-110), `notes_empty_widget.dart`, bottom sheet with Edit + Remove (SC-009; button handlers land in T015/T019/T022), pull-to-refresh (SC-008 transitions)
- [ ] T011 [US1] Register `NotesRepository`, `GetNotesUsecase`, and lazy-singleton `NotesCubit` in `lib/core/injections/notes/notes_service_locator.dart`
- [ ] T012 [US1] Insert `/notes` branch between People and Reminders in `lib/core/router/app_router.dart`; add `Icons.note_rounded` tab with `navNotes` label in `lib/core/router/main_shell.dart`; register refresh callback on `TabRefreshCoordinator`
- [ ] T013 [US1] Tests in `test/features/notes/` (entity valid + null-per-field + `copyWith` + allowlist; `GetNotesUsecase` success + `Left`; cubit `loadNotes` empty → `NotesLoaded([])`, populated, unauthenticated, failure, family-context switch → reload; widget smoke EN + PT)

## Phase 4: US2 Create Note (Priority: P1)

**Goal**: Members create title/content/color notes validated trim-then-check-empty + length.
**Independent test**: Open editor → over-limit/whitespace-only shows localized inline errors, no save; valid save → `NoteActionSuccess`, list reloads with new card newest-first.

- [ ] T014 [US2] Create `CreateNoteUsecase` in `lib/features/notes/domain/usecase/create_note_usecase.dart`
- [ ] T015 [US2] Add `NotesCubit.createNote` in `lib/features/notes/presentation/cubit/notes_cubit.dart` (`NotesLoading` → `NoteActionSuccess` → re-`loadNotes()`); register `CreateNoteUsecase` in `lib/core/injections/notes/notes_service_locator.dart`
- [ ] T016 [US2] Create editor in `lib/features/notes/presentation/views/note_editor_screen.dart` + `note_color_picker_widget.dart` (exactly two toolbar buttons bold/list per FR-109; labels/hints via `notesTitleLabel/Hint`, `notesContentLabel/Hint`; validators `value.trim().isEmpty` → required, `trimmed.length > 100/300` → too-long; markers count toward limit)
- [ ] T017 [US2] Tests in `test/features/notes/` (`CreateNoteUsecase` success + `Left`; cubit create success → `NoteActionSuccess` + reload, failure → `NotesFailure`, dismissed form → neutral state; widget form validation + save wiring)

## Phase 5: US3 Edit Note (Priority: P2)

**Goal**: Members edit any family note via pre-populated form reusing the create design; last-write-wins.
**Independent test**: Sheet → Edit → form pre-populated → save → card updated, `updated_at` bumped; concurrent edit → silent overwrite.

- [ ] T018 [US3] Create `UpdateNoteUsecase` in `lib/features/notes/domain/usecase/update_note_usecase.dart`
- [ ] T019 [US3] Add `NotesCubit.updateNote` in `lib/features/notes/presentation/cubit/notes_cubit.dart` (same success → reload sequence; stale id → localized not-found `NotesFailure` + reload); register `UpdateNoteUsecase` in `lib/core/injections/notes/notes_service_locator.dart`
- [ ] T020 [US3] Tests in `test/features/notes/` (`UpdateNoteUsecase` success + `Left`; cubit update success/failure/stale paths; widget pre-population)

## Phase 6: US4 Delete Note (Priority: P2)

**Goal**: Members hard-delete notes after a localized confirm dialog.
**Independent test**: Sheet → Remove → dialog → confirm → row gone; cancel/dismiss → unchanged list, no failure state.

- [ ] T021 [US4] Create `DeleteNoteUsecase` in `lib/features/notes/domain/usecase/delete_note_usecase.dart`
- [ ] T022 [US4] Add `NotesCubit.deleteNote` in `lib/features/notes/presentation/cubit/notes_cubit.dart` (confirm dialog strings `notesDeleteDialogTitle/Message/Confirm/Cancel`; confirm → hard `DELETE` + reload; dismiss → re-emit `NotesLoaded`); register `DeleteNoteUsecase` in `lib/core/injections/notes/notes_service_locator.dart`
- [ ] T023 [US4] Tests in `test/features/notes/` (`DeleteNoteUsecase` success + `Left`; cubit delete success/cancel/failure paths; widget dialog confirm/cancel wiring)

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T024 [P] FR-110 widget tests in `test/features/notes/` (pump EN + PT with long strings; no `RenderFlex` overflow; titles ellipsize, bodies wrap)
- [ ] T025 [P] Markdown render tests in `test/features/notes/` (`**bold**` spans, `- ` bullet rows, plain text passthrough)
- [ ] T026 [P] Failure-path audit across `lib/features/notes/` (every `Left(Failure)` → distinct UI state; no fake-data fallbacks; `on Object` catches; absence check: no search/filter/sort UI per FR-108)
- [ ] T027 Run gates in order: `fvm flutter analyze` (No issues found!) → `fvm flutter test` (All tests passed!) → `fvm flutter test --coverage` + `python3 tool/check_business_logic_coverage.py` (100% per file under `lib/**/domain/`, no `application/` layer) → `bash tool/check_no_hardcoded_secrets.sh`
- [ ] T028 Reviewer sign-off walkthrough per SC-102 assets (`designs/notes_design*.pdf`, `designs/html/01-FamilyAdmin - Notes*.html`) and update spec/plan/tasks docs for any drift

## Dependencies

- Setup (T001–T003) → Foundational (T004) → US1 (T005–T013) → US2 (T014–T017) → US3 (T018–T020) + US4 (T021–T023, parallel with US3) → Polish (T024–T028)
- DI/router tasks sit after the classes they wire (T011–T012 after T005–T010; T015/T019/T022 extend DI with their own use-case)
- T024/T025/T026 are mutually parallel; T027–T028 run last

## Parallel execution examples

- Setup: T001 + T002 in parallel (SQL file vs lib skeleton, different paths)
- US1: T005 + T006 in parallel (entity vs repo interface, no cross-dependency)
- Stories: US3 + US4 in parallel after US2 (disjoint files except additive cubit methods — coordinate on `notes_cubit.dart`)
- Polish: T024 + T025 + T026 in parallel (separate test/audit concerns)

## Implementation strategy

- **MVP**: Phases 1–3 (US1 list) — vertical slice proving schema, RLS, cubit, nav, tests
- **Incremental**: US2 (create) → US3 (edit) + US4 (delete) in parallel → Polish gates + sign-off
- **Test-first**: SC-100 mandates cubit/entity/use-case tests per story; write story tests alongside implementation
