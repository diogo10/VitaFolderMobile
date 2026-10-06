-- Fix the broken public.moddatetime() trigger helper.
--
-- Context: the previous implementation called
--   jsonb_populate_record(TG_TABLE_NAME::regclass, ...)
-- but the first argument must be a composite ROW VALUE, not a regclass OID,
-- so EVERY update on a table with a moddatetime trigger failed with:
--   ERROR 42804: first argument of jsonb_populate_record must be a row type
--   CONTEXT: PL/pgSQL function moddatetime() line 7 at assignment
-- (reproducible from the dashboard Table Editor, independent of the app).
-- The fix passes NEW (the trigger row value) as the base instead.
--
-- Run in the Supabase dashboard (SQL editor) on the linked project, or via:
--   supabase link --project-ref jheqalwrnztavzxjsdcj
--   supabase db query --linked --file sqls/fix_moddatetime.sql
--
-- Verify afterwards with any direct edit, e.g. in the Table Editor change a
-- note's color: the edit must save and updated_at must advance. Existing
-- grants on the function are preserved by CREATE OR REPLACE.

CREATE OR REPLACE FUNCTION "public"."moddatetime"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  column_name text := COALESCE(TG_ARGV[0], 'updated_at');
begin
  -- Convert NEW row -> jsonb, set the given field to now(), then
  -- convert jsonb back into the NEW row type. Base must be the NEW row
  -- value itself (a regclass OID is not a row type and raises 42804).
  NEW :=
    jsonb_populate_record(
      NEW,
      jsonb_set(to_jsonb(NEW), ARRAY[column_name], to_jsonb(now()))
    );

  return NEW;
end;
$$;
