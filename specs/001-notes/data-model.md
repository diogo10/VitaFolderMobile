# Data Model: 001-notes

**Spec**: [spec.md](spec.md) | **Research**: [research.md](research.md)

## Entities

### Note (Supabase `notes` + `lib/features/notes/domain/entities/note_entity.dart`)

| Field | Type (Dart / SQL) | Constraints |
|---|---|---|
| `id` | `String` / `uuid PK DEFAULT gen_random_uuid()` | Required, UUID parseable; `from` null if missing/unparseable |
| `familyId` | `String` / `uuid NOT NULL REFERENCES families(id) ON DELETE CASCADE` | Isolation scope; required |
| `createdBy` | `String` / `uuid NOT NULL DEFAULT auth.uid()` | Audit-only; required; confers no privilege |
| `title` | `String` / `text NOT NULL` | `trim()` non-empty, `trimmed.length <= 100`; DB `CHECK (char_length(trim(title)) BETWEEN 1 AND 100)` |
| `content` | `String` / `text NOT NULL` | Markdown subset (`**bold**`, `- lists`); `trim()` non-empty, `trimmed.length <= 300` incl. markers; DB `CHECK (char_length(trim(content)) BETWEEN 1 AND 300)` |
| `color` | `String` / `text NOT NULL` | Frozen set `yellow\|pink\|blue\|green\|orange` (lowercase); DB `CHECK (color IN (...))` |
| `createdAt` | `DateTime` / `timestamptz NOT NULL DEFAULT now()` | Required; `from` null on unparseable (no now-fallback) |
| `updatedAt` | `DateTime` / `timestamptz NOT NULL DEFAULT now()` | Bumped by trigger on UPDATE |

`Note.from(dynamic json)` returns `null` on ANY violation (missing/invalid ids, empty-after-trim or over-limit title/content, non-allowlisted color, bad timestamps). `copyWith`, `==`/`hashCode`, `const` constructor. Single palette map `noteColorPalette: Map<String, Color>` (one site only).

### Family (existing, read-only reference)

`families(id)` + membership via `family_memberships(family_id, user_id, role)`. Notes never joins roles; any member has full CRUD within their `family_id` scope. Family resolution client-side via `PeopleRepository.getFamilyIdsForUser`.

## Relationships

- `notes.family_id → families.id` (N:1, cascade delete).
- `notes.created_by → profiles.id` (audit, `ON DELETE SET NULL` or plain uuid per final SQL; no isolation semantics).
- No child tables (no attachments per FR-109).

## Validation rules (enforced in 3 layers)

1. UI validators (editor form): trim-then-check-empty + length; localized errors (`notesTitleRequired/TooLong`, `notesContentRequired/TooLong`).
2. `Note.from` null-on-invalid (same rule; list parsing drops nulls, never substitutes).
3. DB `CHECK`s (trim-aware length + color allowlist) in `sqls/notes_schema.sql` — last line of defense for concurrent/offline races.

## State transitions (list lifecycle, FR-102)

`NotesInitial` → `NotesLoading` → exactly one of `NotesLoaded | NotesUnauthenticated | NotesFailure`. Mutations: `NotesLoading` → `NoteActionSuccess` → re-`loadNotes()` → `NotesLoading` → `NotesLoaded`. Pull-to-refresh (SC-008): indicator → `NotesLoading` → `NotesLoaded` (or localized `NotesFailure` offline). Cancel/dismiss → re-emit current `NotesLoaded`. Ordering always `created_at DESC`. Last-write-wins on concurrent update; hard delete on confirm.
