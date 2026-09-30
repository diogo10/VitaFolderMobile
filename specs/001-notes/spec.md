# Spec: 001-notes

## Summary
Implement a shared Notes feature allowing family members to create, edit, view, and delete color-coded notes scoped to their specific family group, integrated into the main navigation.

## Key Entities
- **Note**: A shared text entry with columns `id: uuid` (PK, `gen_random_uuid()`), `family_id: uuid` NOT NULL REFERENCES `families(id)` ON DELETE CASCADE (isolation scope), `created_by: uuid` NOT NULL `DEFAULT auth.uid()` (audit-only, never an isolation filter), `title: text` NOT NULL, `content: text` NOT NULL, `color: text` NOT NULL constrained to allowlist, `created_at: timestamptz` NOT NULL `DEFAULT now()`, `updated_at: timestamptz` NOT NULL `DEFAULT now()` (bumped on update via trigger).
    - **Constraints**: Title 100 chars, content 300 chars. App-layer rule (UI validators + `Note.from` null-on-invalid) is trim-then-check-empty + length: `value.trim().isEmpty` → required error; `trimmed.length > limit` → too-long error. DB mirrors it with `CHECK (char_length(trim(title)) BETWEEN 1 AND 100 AND char_length(trim(content)) BETWEEN 1 AND 300)` in `sqls/notes_schema.sql` — i.e. DB also trims before length, so whitespace-only or over-limit rows are rejected at the database, not just in the app.
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
- **FR-101**: All note reads/writes MUST be scoped by `family_id` only (`family_id REFERENCES families(id)`). Supabase RLS policies on `notes` MUST enforce `auth.uid()` membership via `family_members`: SELECT/UPDATE/DELETE with `USING (EXISTS (SELECT 1 FROM family_members WHERE family_members.family_id = notes.family_id AND family_members.user_id = auth.uid()))`, INSERT with `WITH CHECK (EXISTS (SELECT 1 FROM family_members WHERE family_members.family_id = NEW.family_id AND family_members.user_id = auth.uid()))`. `user_id` MUST NOT be used as an isolation filter; it is stored only as `created_by` audit field (`DEFAULT auth.uid()`).
- **FR-102**: All business logic MUST be handled by `NotesCubit` (no Supabase imports in `presentation/cubit/`; cubit delegates to injected repository/use-cases and translates `Left(Failure)` to failure states). Sealed states in `notes_state.dart`: `NotesInitial`, `NotesLoading` (emitted first, then exactly one outcome), `NotesUnauthenticated` (for SC-002, when no logged-in user), `NotesLoaded(notes)` (UI distinguishes `notes.isEmpty` empty-state vs populated grid/list; list ordered `created_at DESC`), `NoteActionSuccess` (transient single-action create/update/delete confirmation; list refresh goes through `NotesLoaded`, never `NoteActionSuccess` as list state), `NotesFailure(message)` with localized message. Mutation sequence: `NotesLoading` → `NoteActionSuccess` → re-`loadNotes()` → `NotesLoading` → `NotesLoaded` (e.g. create success emits `NoteActionSuccess`, then reloads and emits `NotesLoading` + `NotesLoaded`). Cancel path (e.g. dismissed sheet) emits neutral state, not failure.
- **FR-103**: Repository methods MUST return `Future<Either<Failure, T>>`.
- **FR-104**: The bottom navigation bar MUST include a localized "Notes" item with a note icon.
- **FR-105**: Database schema MUST be stored in `sqls/notes_schema.sql` with `id: uuid PK`, `family_id: uuid NOT NULL REFERENCES families(id) ON DELETE CASCADE`, `created_by: uuid NOT NULL DEFAULT auth.uid()`, `title/content/color: text NOT NULL`, `created_at/updated_at: timestamptz NOT NULL DEFAULT now()`, color allowlist `CHECK`, length `CHECK (char_length(trim(...)) BETWEEN 1 AND ...)` (trim-aware, see Key Entities), RLS + `updated_at` trigger.
- **FR-106**: Text fields MUST enforce trim-then-check-empty + length limits: Title (100), Note Body (300) — enforced in UI validation and `Note.from` null-on-invalid, mirrored in DB via trim-aware `CHECK (char_length(trim(...)))`.
- **FR-107**: All user-visible strings MUST come via AppLocalizations backed by `lib/l10n/app_en.arb` and `lib/l10n/app_pt.arb` — never hardcode; new keys required for titles, empty/unauthenticated/error states, validation errors (US2), and delete-confirm dialog (US4).
- **FR-108**: Notes list has no search, filter, or alternate sort; ordering is `created_at DESC` only.
- **FR-109**: Note body supports rich-text formatting (bold/lists) in create/edit/view; image/file attachments are out of scope (no storage columns or upload flows).

## Edge Cases
- User loses internet connection while saving: Cubit should emit `NotesFailure` with localized error message.
- Offline viewing: no cache; opening the list or saving while offline emits localized `NotesFailure` until pull-to-refresh succeeds online. No local persistence or queued retry.
- Note is deleted by another user while current user is viewing it: pull-to-refresh re-syncs to `NotesLoaded`; edit/delete on a stale note surfaces localized `NotesFailure` (not-found) and triggers list reload rather than crashing or showing fake data.
- User changes family context: Notes list must refresh to the new `family_id`.
- Permission model: any current `family_members` member may create notes and edit/delete any note in their `family_id` scope (shared family space); RLS denies non-members on all operations and the cubit maps denial to `NotesUnauthenticated`/`NotesFailure` with localized message. `created_by` confers no extra edit/delete privilege.
- Concurrent edits: last-write-wins applies; the later update overwrites silently with `updated_at` bumped via trigger, with no version check or conflict UI.
- Deletion is hard delete: confirm-dialog confirm permanently erases the row with no trash, restore, or `deleted_at` column.

## Success Criteria
- **SC-100**: 100% test coverage on `domain/` and `application/` layers. Explicit test list: cubit tests (`loadNotes` empty → `NotesLoaded([])`, populated → `NotesLoaded(notes)`, unauthenticated → `NotesUnauthenticated`, failure → `NotesFailure`, `create/update/deleteNote` success → `NoteActionSuccess` + reload, failure paths, family-context switch refresh); entity tests (`Note.from` valid, null-on-invalid per field, `copyWith`, color allowlist); use-case tests (`GetNotesUsecase`, `CreateNoteUsecase`, `UpdateNoteUsecase`, `DeleteNoteUsecase` success + `Left(Failure)` paths).
- **SC-101**: `fvm flutter analyze` reports no issues.
- **SC-102**: UI matches design assets exactly: `designs/notes_design.pdf` (populated list), `designs/notes_design_empty_list.pdf` (empty list), `designs/notes_design_create_note.pdf` (create form, US2), `designs/notes_design_empty_state_for_unlogged_user.pdf` (unauthenticated, SC-002); additionally `designs/html/01-FamilyAdmin - Notes.html`, `designs/html/01-FamilyAdmin - Notes (Empty).html`, `designs/html/01-FamilyAdmin - Notes (Create).html`.

## Clarifications
### Session 2026-09-30 with User
- **Q**: Is there a character limit for title/note?
- **A**: Title should have 100 characters and notes should have 300 characters.
- **Q**: Real-time sync required or pull-to-refresh?
- **A**: Add a pull-to-refresh.
- Q: How should the app handle two family members editing the same note at the same time? → A: Last-write-wins
- Q: What should the user see when opening Notes with no internet connection? → A: Error only, no cache
- Q: Does the Notes list need search, filtering, or sorting beyond newest-first order? → A: No search/filter; created_at DESC only
- Q: Should deleting a note permanently erase it or move it to a recoverable trash? → A: Hard delete immediately with confirm dialog, no restore
- Q: Are attachments, images, or rich-text formatting part of this Notes release? → A: Rich-text formatting (bold/lists) only, no files
