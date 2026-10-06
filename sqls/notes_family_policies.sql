-- Sync the notes RLS policies to the family-member model.
--
-- Context: the app sends color (and title/content) on every note update and
-- treats a zero-row write as a failure. If the live `public.notes` table is
-- missing the UPDATE policy below (or carries a creator-only variant), edits
-- — including color-only edits — are filtered to zero rows and the app
-- reports a localized error while the table keeps the old values. This
-- script (re)applies the four family-member policies idempotently: safe to
-- run whether the live table matches, partially matches, or predates them.
--
-- Run in the Supabase dashboard (SQL editor) on the linked project, or via:
--   supabase link --project-ref jheqalwrnztavzxjsdcj
--   supabase db query --linked --file sqls/notes_family_policies.sql
--
-- Verify afterwards (expect the four notes_*_member policies):
--   SELECT policyname, cmd, roles
--   FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'notes'
--   ORDER BY policyname;

ALTER TABLE "public"."notes" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notes_select_member" ON "public"."notes";
CREATE POLICY "notes_select_member" ON "public"."notes"
    FOR SELECT TO "authenticated"
    USING (
        EXISTS (
            SELECT 1 FROM "public"."family_memberships" "fm"
            WHERE "fm"."family_id" = "notes"."family_id"
            AND "fm"."user_id" = "auth"."uid"()
        )
    );

DROP POLICY IF EXISTS "notes_insert_member" ON "public"."notes";
CREATE POLICY "notes_insert_member" ON "public"."notes"
    FOR INSERT TO "authenticated"
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "public"."family_memberships" "fm"
            WHERE "fm"."family_id" = "notes"."family_id"
            AND "fm"."user_id" = "auth"."uid"()
        )
    );

DROP POLICY IF EXISTS "notes_update_member" ON "public"."notes";
CREATE POLICY "notes_update_member" ON "public"."notes"
    FOR UPDATE TO "authenticated"
    USING (
        EXISTS (
            SELECT 1 FROM "public"."family_memberships" "fm"
            WHERE "fm"."family_id" = "notes"."family_id"
            AND "fm"."user_id" = "auth"."uid"()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "public"."family_memberships" "fm"
            WHERE "fm"."family_id" = "notes"."family_id"
            AND "fm"."user_id" = "auth"."uid"()
        )
    );

DROP POLICY IF EXISTS "notes_delete_member" ON "public"."notes";
CREATE POLICY "notes_delete_member" ON "public"."notes"
    FOR DELETE TO "authenticated"
    USING (
        EXISTS (
            SELECT 1 FROM "public"."family_memberships" "fm"
            WHERE "fm"."family_id" = "notes"."family_id"
            AND "fm"."user_id" = "auth"."uid"()
        )
    );

GRANT ALL ON TABLE "public"."notes" TO "anon";
GRANT ALL ON TABLE "public"."notes" TO "authenticated";
GRANT ALL ON TABLE "public"."notes" TO "service_role";
