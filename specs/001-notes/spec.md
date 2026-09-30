# Spec: 001-notes

## Summary
Implement a shared Notes feature allowing family members to create, edit, view, and delete color-coded notes scoped to their specific family group, integrated into the main navigation.

## Key Entities
- **Note**: A shared text entry with columns `id: uuid` (PK, `gen_random_uuid()`), `family_id: uuid` NOT NULL FK (isolation scope), `created_by: uuid` NOT NULL `DEFAULT auth.uid()` (audit-only, never an isolation filter), `title: text` NOT NULL, `content: text` NOT NULL, `color: text` NOT NULL constrained to allowlist, `created_at: timestamptz` NOT NULL `DEFAULT now()`, `updated_at: timestamptz` NOT NULL `DEFAULT now()` (bumped on update via trigger).
    - **Constraints**: Title 100 chars, content 300 chars. Validation rule everywhere is trim-then-check-empty + length: `value.trim().isEmpty` → required error; `trimmed.length > limit` → too-long error. Mirrored identically in UI validators, in `Note.from` null-on-invalid, and in DB via `CHECK (char_length(title) <= 100 AND char_length(content) <= 300)` in `sqls/notes_schema.sql`.
    - **Color allowlist**: Store canonical lowercase names only (e.g. `yellow | pink | blue | green | orange`); enforced by DB `CHECK (color IN (...))` and by `Note.from` null-on-invalid. Map to UI palette (`Color` values) in exactly one place (e.g. a single `noteColorPalette` map); UI sends/stores only allowlisted names — never raw `Color.toString()` or hex.
    - `Note.from(dynamic json)` returns `null` on any bad input (missing/invalid `id`/`family_id`/`created_by`, empty-after-trim or over-limit title/content, non-allowlisted color, bad timestamps) — never fall back to defaults.
- **Family**: The grouping entity to which the note belongs; membership looked up via `family_members` (`family_id` + `user_id = auth.uid()`).

## User Stories

### US1: View Notes List (High)
**As a** family member, 
**I want** to see a list of notes shared with my family, 
**so that** I can stay informed about family updates.
- **SC-001**: Display empty state if no notes exist.
- **SC-002**: Show unauthenticated state if the user is not logged in.
- **SC-003**: Render notes in a grid/list with their assigned background colors.
- **SC-008**: Support pull-to-refresh to manually sync the list with the backend.
- **Given** I am on the Notes screen, **When** data is loaded, **Then** I see the list of family notes.

### US2: Create Note (High)
**As a** family member, 
**I want** to create a new note with a title, text, and color, 
**so that** I can share information with my family.
- **SC-004**: Validate with trim-then-check-empty + length (100 title / 300 content) in the UI; validation errors shown via AppLocalizations strings (backed by `lib/l10n/app_en.arb` + `lib/l10n/app_pt.arb`, e.g. `notesTitleRequired`, `notesTitleTooLong`, `notesContentRequired`, `notesContentTooLong`). Same rule mirrored in `Note.from` (null-on-invalid) and DB `CHECK`.
- **SC-005**: Allow selection from a set of predefined colors (color allowlist only).
- **Given** I am on the 'Create Note' screen, **When** I tap 'Save', **Then** the note is persisted to Supabase with `family_id` scope plus `created_by = auth.uid()` audit field, and I return to the list.

### US3: Edit Note (Medium)
**As a** family member, 
**I want** to modify an existing note, 
**so that** I can update outdated information.
- **SC-006**: Form must be pre-populated with existing note data.
- **Given** I select 'Edit' from a note's bottom sheet, **When** I modify and save, **Then** the record is updated in the database.

### US4: Delete Note (Medium)
**As a** family member, 
**I want** to remove a note, 
**so that** I can clean up the shared space.
- **SC-007**: Selecting 'Remove' from the bottom sheet shows a localized confirm dialog (AppLocalizations strings, e.g. `notesDeleteDialogTitle`, `notesDeleteDialogMessage`, `notesDeleteDialogConfirm`/`Cancel`) backed by `lib/l10n/app_en.arb` + `lib/l10n/app_pt.arb`; on confirm the record is deleted.
- **Given** I select 'Remove', **When** I confirm, **Then** the note is deleted and the list refreshes.

## Functional Requirements
- **FR-101**: All note reads/writes MUST be scoped by `family_id` only. Supabase RLS policies on `notes` MUST enforce `auth.uid()` membership via `family_members` (e.g. `EXISTS (SELECT 1 FROM family_members WHERE family_members.family_id = notes.family_id AND family_members.user_id = auth.uid())`) for SELECT/INSERT/UPDATE/DELETE, with `WITH CHECK` on writes. `user_id` MUST NOT be used as an isolation filter; it is stored only as `created_by` audit field (`DEFAULT auth.uid()`).
- **FR-102**: All business logic MUST be handled by `NotesCubit` (no Supabase imports in `presentation/cubit/`; cubit delegates to injected repository/use-cases and translates `Left(Failure)` to failure states). Sealed states in `notes_state.dart`: `NotesInitial`, `NotesLoading` (emitted first, then exactly one outcome), `NotesUnauthenticated` (for SC-002, when no logged-in user), `NotesLoaded(notes)` (UI distinguishes `notes.isEmpty` empty-state vs populated grid/list; list ordered `created_at DESC`), `NoteActionSuccess` (transient single-action create/update/delete confirmation; list refresh goes through `NotesLoaded`, never `NoteActionSuccess` as list state), `NotesFailure(message)` with localized message. Mutation sequence: `NotesLoading` → `NoteActionSuccess` → re-`loadNotes()` → `NotesLoading` → `NotesLoaded` (e.g. create success emits `NoteActionSuccess`, then reloads and emits `NotesLoading` + `NotesLoaded`). Cancel path (e.g. dismissed sheet) emits neutral state, not failure.
- **FR-103**: Repository methods MUST return `Future<Either<Failure, T>>`.
- **FR-104**: The bottom navigation bar MUST include a localized "Notes" item with a note icon.
- **FR-105**: Database schema MUST be stored in `sqls/notes_schema.sql` with `id: uuid PK`, `family_id: uuid NOT NULL`, `created_by: uuid NOT NULL DEFAULT auth.uid()`, `title/content/color: text NOT NULL`, `created_at/updated_at: timestamptz NOT NULL DEFAULT now()`, color allowlist `CHECK`, length `CHECK (char_length(...))`, RLS + `updated_at` trigger.
- **FR-106**: Text fields MUST enforce trim-then-check-empty + length limits: Title (100), Note Body (300) — mirrored in UI validation, `Note.from` null-on-invalid, and DB `CHECK (char_length(...))`.
- **FR-107**: All user-visible strings MUST come via AppLocalizations backed by `lib/l10n/app_en.arb` and `lib/l10n/app_pt.arb` — never hardcode; new keys required for titles, empty/unauthenticated/error states, validation errors (US2), and delete-confirm dialog (US4).

## Edge Cases
- User loses internet connection while saving: Cubit should emit `NotesFailure` with localized error message.
- Note is deleted by another user while current user is viewing it: pull-to-refresh re-syncs to `NotesLoaded`; edit/delete on a stale note surfaces localized `NotesFailure` (not-found) and triggers list reload rather than crashing or showing fake data.
- User changes family context: Notes list must refresh to the new `family_id`.
- Permission model: any current `family_members` member may create notes and edit/delete any note in their `family_id` scope (shared family space); RLS denies non-members on all operations and the cubit maps denial to `NotesUnauthenticated`/`NotesFailure` with localized message. `created_by` confers no extra edit/delete privilege.

## Success Criteria
- **SC-100**: 100% test coverage on `domain/` and `application/` layers. Explicit test list: cubit tests (`loadNotes` empty → `NotesLoaded([])`, populated → `NotesLoaded(notes)`, unauthenticated → `NotesUnauthenticated`, failure → `NotesFailure`, `create/update/deleteNote` success → `NoteActionSuccess` + reload, failure paths, family-context switch refresh); entity tests (`Note.from` valid, null-on-invalid per field, `copyWith`, color allowlist); use-case tests (`GetNotesUsecase`, `CreateNoteUsecase`, `UpdateNoteUsecase`, `DeleteNoteUsecase` success + `Left(Failure)` paths).
- **SC-101**: `fvm flutter analyze` reports no issues.
- **SC-102**: UI matches design assets exactly: `designs/notes_design.pdf` (populated list), `designs/notes_design_empty_state.pdf` (empty list). Requested `designs/notes_design_empty_list.pdf`, `designs/notes_design_create_note.pdf`, and `designs/notes_design_empty_state_for_unlogged_user.pdf` are NOT in the repo — add them in the same PR before referencing them. No `designs/html/` references unless the HTML file is added in the same PR.

## Clarifications
### Session 2026-09-30 with User
- **Q**: Is there a character limit for title/note?
- **A**: Title should have 100 characters and notes should have 300 characters.
- **Q**: Real-time sync required or pull-to-refresh?
- **A**: Add a pull-to-refresh.