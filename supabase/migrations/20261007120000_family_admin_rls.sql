-- Family admin RLS hardening (leave-family PR follow-up).
--
-- Tightens the permissive USING (true) policies dumped in
-- sqls/database_schema.sql:281 (families_auth_delete),
-- sqls/database_schema.sql:293 (families_auth_update) and
-- sqls/database_schema.sql:300 (family_memberships_auth_delete):
--
--   * families UPDATE / DELETE: owner/admin of that family only.
--   * family_memberships DELETE: the member themselves (self-leave) or
--     an owner/admin of that family (admin remove).
--
-- Client-side cubit guards are UX/defense-in-depth only; these policies
-- are the security boundary for destructive membership paths.

-- Helper bypassing RLS (SECURITY DEFINER) so the membership policies can
-- safely reference family_memberships without self-recursion.
CREATE OR REPLACE FUNCTION "public"."is_family_admin"("p_family_id" "uuid")
RETURNS boolean
LANGUAGE "sql"
SECURITY DEFINER
SET "search_path" TO 'public'
AS $$
    SELECT EXISTS (
        SELECT 1 FROM "public"."family_memberships" "m"
        WHERE "m"."family_id" = "p_family_id"
          AND "m"."user_id" = "auth"."uid"()
          AND "m"."role" IN ('owner', 'admin')
    );
$$;

GRANT EXECUTE ON FUNCTION "public"."is_family_admin"("uuid")
    TO "authenticated";

-- families UPDATE: admin/owner-only.
DROP POLICY IF EXISTS "families_auth_update" ON "public"."families";
CREATE POLICY "families_admin_update" ON "public"."families"
    FOR UPDATE TO "authenticated"
    USING ("public"."is_family_admin"("id"))
    WITH CHECK ("public"."is_family_admin"("id"));

-- families DELETE: admin/owner-only.
DROP POLICY IF EXISTS "families_auth_delete" ON "public"."families";
CREATE POLICY "families_admin_delete" ON "public"."families"
    FOR DELETE TO "authenticated"
    USING ("public"."is_family_admin"("id"));

-- family_memberships DELETE: self (leave) or admin/owner (remove).
DROP POLICY IF EXISTS "family_memberships_auth_delete"
    ON "public"."family_memberships";
CREATE POLICY "family_memberships_self_or_admin_delete"
    ON "public"."family_memberships"
    FOR DELETE TO "authenticated"
    USING (
        "user_id" = "auth"."uid"()
        OR "public"."is_family_admin"("family_id")
    );
