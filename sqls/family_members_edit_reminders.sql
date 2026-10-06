-- Let family members edit and delete each other's reminders.
--
-- Context: the reminders UPDATE/DELETE policies previously allowed only the
-- row creator (created_by = auth.uid()). Editing a family member's reminder
-- then silently touched zero rows while the API returned success, so the app
-- reported a successful edit that never persisted. The new policies allow
-- the creator OR any member of the reminder's family (via
-- public.family_memberships). SELECT stays open, which also satisfies the
-- Postgres requirement that UPDATE can first SELECT the row.
--
-- Run in the Supabase dashboard (SQL editor) on the linked project, or via:
--   supabase link --project-ref jheqalwrnztavzxjsdcj
--   supabase db query --linked --file sqls/family_members_edit_reminders.sql
--
-- Verify afterwards (expect the two new policies):
--   SELECT policyname, cmd, roles
--   FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'reminders'
--   ORDER BY policyname;

DROP POLICY IF EXISTS "Enable update for authenticated users (own rows)"
  ON public.reminders;
DROP POLICY IF EXISTS "Enable delete for users based on user_id"
  ON public.reminders;

CREATE POLICY "Family members can update reminders"
  ON public.reminders FOR UPDATE TO authenticated
  USING (
    reminders.created_by = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1
      FROM public.family_memberships AS m
      WHERE m.family_id = reminders.family_id
        AND m.user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    reminders.created_by = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1
      FROM public.family_memberships AS m
      WHERE m.family_id = reminders.family_id
        AND m.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Family members can delete reminders"
  ON public.reminders FOR DELETE TO authenticated
  USING (
    reminders.created_by = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1
      FROM public.family_memberships AS m
      WHERE m.family_id = reminders.family_id
        AND m.user_id = (SELECT auth.uid())
    )
  );
