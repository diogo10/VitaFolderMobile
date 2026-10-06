-- Allow the 'yearly' repeat rule on public.reminders.
--
-- Context: the app sends repeat_rule values never | daily | weekly |
-- monthly | yearly on both create (insert) and edit (update). If the live
-- table carries a CHECK constraint allow-listing only a subset of these
-- values, writes with 'yearly' are rejected with a 400
-- ("new row violates check constraint") and the Supabase table keeps the
-- old value. This script removes any such constraint, idempotently: it is
-- a no-op when no repeat_rule CHECK constraint exists.
--
-- Run in the Supabase dashboard (SQL editor) on the linked project, or via:
--   supabase link --project-ref jheqalwrnztavzxjsdcj
--   supabase db execute --file sqls/allow_yearly_repeat_rule.sql
--
-- Verify afterwards (expect zero rows mentioning repeat_rule):
--   SELECT conname, pg_get_constraintdef(oid)
--   FROM pg_constraint
--   WHERE conrelid = 'public.reminders'::regclass
--     AND pg_get_constraintdef(oid) ILIKE '%repeat_rule%';

DO $$
DECLARE
  c RECORD;
BEGIN
  FOR c IN
    SELECT conname
    FROM pg_constraint
    WHERE conrelid = 'public.reminders'::regclass
      AND contype = 'c'
      AND pg_get_constraintdef(oid) ILIKE '%repeat_rule%'
  LOOP
    EXECUTE format(
      'ALTER TABLE public.reminders DROP CONSTRAINT %I',
      c.conname
    );
  END LOOP;
END
$$;
