# Contract: notes schema (Supabase)

**Spec**: [../spec.md](../spec.md) | **Target file**: `sqls/notes_schema.sql`

> Implementation phase creates `sqls/notes_schema.sql` satisfying this contract. Table/column names and CHECK shapes are frozen here; RLS uses `family_memberships` (see [research](../research.md) R2).

- Table `notes`: `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`, `family_id uuid NOT NULL REFERENCES families(id) ON DELETE CASCADE`, `created_by uuid NOT NULL DEFAULT auth.uid()`, `title text NOT NULL`, `content text NOT NULL`, `color text NOT NULL`, `created_at timestamptz NOT NULL DEFAULT now()`, `updated_at timestamptz NOT NULL DEFAULT now()`.
- Checks: `CHECK (color IN ('yellow','pink','blue','green','orange'))`; `CHECK (char_length(btrim(title)) BETWEEN 1 AND 100 AND char_length(btrim(content)) BETWEEN 1 AND 300)` (`btrim` — bare `trim()` is keyword syntax in Postgres, not a callable function).
- `updated_at` trigger on UPDATE (`SET updated_at = now()`).
- RLS enabled + 4 policies: SELECT/UPDATE/DELETE `USING (EXISTS (SELECT 1 FROM family_memberships WHERE family_memberships.family_id = notes.family_id AND family_memberships.user_id = auth.uid()))`; INSERT `WITH CHECK (EXISTS (SELECT 1 FROM family_memberships WHERE family_memberships.family_id = NEW.family_id AND family_memberships.user_id = auth.uid()))`.
- Client query shape: `from('notes').select().eq('family_id', familyId).order('created_at', ascending: false)`; mutations set `family_id` + rely on `created_by` default.

## L10n keys (EN + PT, `lib/l10n/app_en.arb` / `app_pt.arb`)

`navNotes`, `notesTitle`, `notesTitleLabel`, `notesTitleHint`, `notesContentLabel`, `notesContentHint`, `notesEmptyTitle`, `notesEmptyMessage`, `notesUnauthenticatedTitle`, `notesUnauthenticatedMessage`, `notesTitleRequired`, `notesTitleTooLong`, `notesContentRequired`, `notesContentTooLong`, `notesCreateTitle`, `notesEditTitle`, `notesSave`, `notesDeleteDialogTitle`, `notesDeleteDialogMessage`, `notesDeleteDialogConfirm`, `notesDeleteDialogCancel`, `notesErrorGeneric`, `notesErrorNotFound`, `notesErrorOffline`.
