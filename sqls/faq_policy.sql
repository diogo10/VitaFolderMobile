-- FAQ RLS policies (public read-only Help & FAQ content).
--
-- Context: public.faqs is a single global table (same entries for every
-- user, NOT scoped to family_memberships). The Help & FAQ screen is
-- browsable as a guest, so both anon and authenticated roles get SELECT.
-- No INSERT/UPDATE/DELETE policies are created for client roles: writes
-- are service_role-only (service_role bypasses RLS). This mirrors the
-- policy block at the end of sqls/faq_schema.sql, extracted so policies
-- can be (re)applied without touching the table definition. Idempotent:
-- safe to re-run at any time.
--
-- Run in the Supabase dashboard (SQL editor) on the linked project, or via:
--   supabase link --project-ref jheqalwrnztavzxjsdcj
--   supabase db query --linked --file sqls/faq_policy.sql
--
-- Verify afterwards (expect public read policies only, RLS enabled):
--   SELECT policyname, cmd, roles
--   FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'faqs'
--   ORDER BY policyname;

ALTER TABLE "public"."faqs" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "faqs_select_public" ON "public"."faqs";
CREATE POLICY "faqs_select_public" ON "public"."faqs"
    FOR SELECT TO "anon", "authenticated"
    USING (true);

GRANT SELECT ON TABLE "public"."faqs" TO "anon";
GRANT SELECT ON TABLE "public"."faqs" TO "authenticated";
GRANT ALL ON TABLE "public"."faqs" TO "service_role";
