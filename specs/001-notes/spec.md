# Spec: 001-notes

## Summary
Implement a shared Notes feature allowing family members to create, edit, view, and delete color-coded notes scoped to their specific family group, integrated into the main navigation.

## Key Entities
- **Note**: A shared text entry containing a title, content, and UI color. [NEEDS CLARIFICATION: Is there a character limit for title/note?]
- **Family**: The grouping entity to which the note belongs.

## User Stories

### US1: View Notes List (High)
**As a** family member, 
**I want** to see a list of notes shared with my family, 
**so that** I can stay informed about family updates.
- **SC-001**: Display empty state if no notes exist.
- **SC-002**: Show unauthenticated state if the user is not logged in.
- **SC-003**: Render notes in a grid/list with their assigned background colors.
- **Given** I am on the Notes screen, **When** data is loaded, **Then** I see the list of family notes.

### US2: Create Note (High)
**As a** family member, 
**I want** to create a new note with a title, text, and color, 
**so that** I can share information with my family.
- **SC-004**: Validate that title and note text are not empty.
- **SC-005**: Allow selection from a set of predefined colors.
- **Given** I am on the 'Create Note' screen, **When** I tap 'Save', **Then** the note is persisted to Supabase and I return to the list.

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
- **SC-007**: Selecting 'Remove' from the bottom sheet deletes the record.
- **Given** I select 'Remove', **When** I confirm, **Then** the note is deleted and the list refreshes.

## Functional Requirements
- **FR-101**: Data MUST be scoped by `user_id` and `family_id` in Supabase.
- **FR-102**: All business logic MUST be handled by `NotesCubit` emitting states: `Loading`, `NotesLoaded`, `NoteActionSuccess`, `Failure`.
- **FR-103**: Repository methods MUST return `Future<Either<Failure, T>>`.
- **FR-104**: The bottom navigation bar MUST include a localized "Notes" item with a note icon.
- **FR-105**: Database schema MUST be stored in `sqls/notes_schema.sql`.

## Edge Cases
- User loses internet connection while saving: Cubit should emit `Failure` with localized error message.
- Note is deleted by another user while current user is viewing it: [NEEDS CLARIFICATION: Real-time sync required or pull-to-refresh?]
- User changes family context: Notes list must refresh to the new `family_id`.

## Success Criteria
- **SC-100**: 100% test coverage on `domain/` and `application/` layers.
- **SC-101**: `fvm flutter analyze` reports no issues.
- **SC-102**: UI matches provided HTML design states exactly.