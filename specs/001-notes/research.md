# Research: 001-notes

**Date**: 2026-09-30 | **Spec**: [spec.md](spec.md) | **Branch**: `001-notes`

All Technical Context unknowns resolved. No NEEDS CLARIFICATION remains.

## R1: Repository / Cubit pattern to follow

- **Decision**: Mirror `lib/features/reminders/` exactly: hand-written immutable entity + `*Model extends Entity` with `fromMap`/`toCreate`/`toUpdate` + `*Repository` interface returning `Future<Either<Failure,T>>` + thin use-cases per operation + single list `NotesCubit` (FR-102 mandates one cubit, so unlike reminders' split `RemindersCubit`/`CreateReminderCubit`, editor actions are methods on `NotesCubit`) + `*ServiceLocator(sl).init()` aggregated in `service_locator.dart`.
- **Rationale**: Reminders is the closest shipped analog (family-scoped Supabase CRUD, `family_id` isolation, `created_by` audit, `Either` boundary with `on Failure`/`on Object` catches, `PeopleRepository` family resolution). Reuse minimizes review surface and satisfies constitution II/III/V/VI.
- **Alternatives considered**: New generic base-repository abstraction — rejected (no precedent in codebase, adds complexity); Riverpod/service-layer orchestration — rejected (constitution mandates Cubit + GetIt).

## R2: Membership table (`family_memberships`)

- **Decision**: Implement against the real table `family_memberships` (`family_id`, `user_id`, `role`). All `sqls/notes_schema.sql` RLS predicates use `EXISTS (SELECT 1 FROM family_memberships fm WHERE fm.family_id = notes.family_id AND fm.user_id = auth.uid())` (SELECT/UPDATE/DELETE `USING`, INSERT `WITH CHECK`), mirroring the `reminders` policies in `sqls/database_schema.sql:202-205`.
- **Rationale**: Spec and codebase agree on `family_memberships` (`families`/`family_memberships` in the live `sqls/database_schema.sql`, `people_repository_impl.dart`, `auth_service.dart`). All `sqls/notes_schema.sql` RLS predicates use `EXISTS (SELECT 1 FROM family_memberships fm WHERE fm.family_id = notes.family_id AND fm.user_id = auth.uid())` (SELECT/UPDATE/DELETE `USING`, INSERT `WITH CHECK`), mirroring the `reminders` policies in `sqls/database_schema.sql`.
- **Alternatives considered**: A second `family_members` table — rejected (would fork the permission model; RLS would never match).

## R3: Rich-text storage (FR-109 bold/lists, 300-char limit, no attachments)

- **Decision**: Store `content` as plain `text` with a lightweight markdown subset (`**bold**` inline, `- ` list-line prefix). View renders via `Text.rich` with a ~50-line parser (bold spans + bullet rows); editor is a plain `TextField` with a bold/list toolbar that inserts markers. The 300-char `CHECK`/validator counts the raw stored string including markers (documented in quickstart + placeholder/hint strings).
- **Rationale**: `content TEXT NOT NULL` + trim-aware `char_length(trim(content)) BETWEEN 1 AND 300` CHECK cannot hold opaque Delta/HTML without redefining what "300 characters" means. Markdown-subset keeps DB, `Note.from`, and UI validators measuring the same string, needs zero new dependencies, and satisfies "bold/lists only, no files".
- **Alternatives considered**: `flutter_quill` + Delta JSON — rejected (heavy dep, JSON wrapper breaks char-limit semantics, new serialization + migration surface); HTML storage — rejected (tag overhead vs 300 limit, XSS-sanitizer surface); full markdown package — rejected (unneeded; only two constructs required).

## R4: Color allowlist ↔ UI palette mapping

- **Decision**: Canonical lowercase names `yellow | pink | blue | green | orange` stored in DB; single `noteColorPalette: Map<String, Color>` in `lib/features/notes/domain/entities/note_color.dart` (or `presentation/` theme-adjacent constant imported once). `Note.from` returns null for any other value; UI picker offers exactly the 5 swatches; `toCreate`/`toUpdate` send only the name — never `Color.toString()`/hex.
- **Rationale**: Spec mandates single mapping site + DB `CHECK (color IN (...))` + null-on-invalid. Matches `ReminderType.fromString` enum pattern.
- **Alternatives considered**: Dart `enum NoteColor { yellow, ... }` with `.name` — acceptable equivalent; chosen map-vs-enum is implementation detail as long as one canonical site exists.

## R5: State machine + mutation reload sequence

- **Decision**: Sealed `notes_state.dart`: `NotesInitial`, `NotesLoading`, `NotesUnauthenticated`, `NotesLoaded(List<NoteEntity>)`, `NoteActionSuccess`, `NotesFailure(String message)`. Every cubit method emits `NotesLoading` first then exactly one outcome. Mutations emit `NoteActionSuccess`, then internally re-`loadNotes()` (`NotesLoading` → `NotesLoaded`). Dismissed sheets re-emit current `NotesLoaded`, never failure. Stale edit/delete → `NotesFailure` (localized not-found) + reload.
- **Rationale**: Direct transcription of FR-102 + SC-100 sequences; compatible with `RemindersCubit` loading-flag idiom while satisfying the stricter sealed-states gate.
- **Alternatives considered**: Separate `CreateNoteCubit` — rejected (FR-102: "All business logic MUST be handled by `NotesCubit`").

## R6: Navigation — tab position + factory contract

- **Decision**: Insert Notes as a new tab between People and Reminders (`/notes`, `Icons.note_rounded`, `navNotes` label) per clarified FR-104; branches after it shift one index (deep links/tests updated). Tab cubit = shared GetIt lazy singleton via `BlocProvider.value`; editor sheet/route (`/notes/edit`) reuses the same cubit instance methods (or fresh-params wrapper that still delegates to `NotesCubit`). Tab builders register on `refreshCoordinator` like siblings; family switch triggers `loadNotes()`.
- **Rationale**: `MainShell._tabIcons`/`_tabLabels` are parallel arrays; the clarified order (Home, People, Notes, Reminders, Account) is inserted in one edit with branch indices and tests updated together.
- **Alternatives considered**: Appending Notes last — rejected (clarified FR-104 requires between People and Reminders); separate editor cubit — rejected per R5.

## R8: Bottom sheet, design reuse, acceptance (SC-009/SC-102, FR-110)

- **Decision**: Tap → bottom sheet with Edit + Remove only, mirroring `lib/features/reminders/presentation/widgets/reminder_widget.dart` (`_showMenu` → `_ReminderMenuSheet`: transparent `showModalBottomSheet`, Edit + Remove rows, `AlertDialog` confirm via `_onRemove`) — no new sheet component; edit form reuses the create-note screen as-is (pre-populated per SC-006); acceptance is reviewer sign-off per design asset (SC-102), not pixel-diff automation; FR-110 dual-locale overflow coverage comes from widget tests pumping EN + PT with no `RenderFlex` overflow (no golden tests).
- **Rationale**: Reuse keeps the new-widget surface to card/picker/empty states; sign-off fits the project's manual design-review practice and the pre-implementation UX checklist (10/10); locale overflow is a layout invariant best pinned by widget tests in both locales.
- **Alternatives considered**: New bespoke sheet component — rejected (duplicates reminders pattern); golden/screenshot tests — rejected (brittle across fonts/locales, no precedent in repo); pixel-tolerance automation — rejected (no harness; sign-off is the specified method).

## R7: Offline / concurrency / delete semantics

- **Decision**: No cache, no queue, no version column. Offline open/save → `NotesFailure` localized; pull-to-refresh is the only sync. Concurrent edit → last-write-wins (no `version`/`etag`). Delete → hard `DELETE` after localized confirm dialog, no `deleted_at`/trash.
- **Rationale**: Spec edge cases + clarifications dictate exactly this; keeps data model to 7 columns + trigger.
- **Alternatives considered**: Optimistic cache / queued retry / soft delete — all rejected as out-of-scope per spec.
