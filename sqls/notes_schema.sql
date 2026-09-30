-- Notes schema for 001-notes (Shared Family Notes).
--
-- Target: Supabase Postgres (dev project). Mirrors the reminders RLS shape
-- but scoped to family_memberships (family_id, user_id).
-- Contracts: specs/001-notes/contracts/notes_schema.md

CREATE TABLE IF NOT EXISTS "public"."notes" (
    "id" "uuid" DEFAULT gen_random_uuid() NOT NULL,
    "family_id" "uuid" NOT NULL,
    "created_by" "uuid" NOT NULL DEFAULT "auth"."uid"(),
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "color" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT "notes_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "notes_color_check"
        CHECK ("color" IN ('yellow', 'pink', 'blue', 'green', 'orange')),
    CONSTRAINT "notes_length_check"
        CHECK (
            char_length(btrim("title")) BETWEEN 1 AND 100
            AND char_length(btrim("content")) BETWEEN 1 AND 300
        )
);

ALTER TABLE ONLY "public"."notes"
    ADD CONSTRAINT "notes_family_id_fkey"
    FOREIGN KEY ("family_id")
    REFERENCES "public"."families"("id")
    ON DELETE CASCADE;

-- Keep updated_at fresh on every UPDATE (same moddatetime helper used
-- elsewhere in database_schema.sql).
DROP TRIGGER IF EXISTS "notes_moddatetime" ON "public"."notes";
CREATE TRIGGER "notes_moddatetime"
    BEFORE UPDATE ON "public"."notes"
    FOR EACH ROW
    EXECUTE FUNCTION "public"."moddatetime"('updated_at');

ALTER TABLE "public"."notes" ENABLE ROW LEVEL SECURITY;

-- Family members (any role) get full CRUD within their family_id scope.
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
