-- FAQ schema (Help & FAQ content migrated from docs/faq/README.md).
--
-- Target: Supabase Postgres (dev project). Single global table: FAQ entries
-- are the same for every user, so (unlike reminders/notes) they are NOT
-- scoped to family_memberships. Authenticated and anonymous clients get
-- read-only access; all writes go through service_role (dashboard, seeds,
-- or future admin tooling).
--
-- Run in the Supabase dashboard (SQL editor) on the linked project, or via:
--   supabase link --project-ref jheqalwrnztavzxjsdcj
--   supabase db query --linked --file sqls/faq_schema.sql
--
-- Then load the content (safe to re-run; see the seed header):
--   supabase db query --linked --file sqls/faq_seed.sql
--
-- Verify afterwards (expect public read policies only, RLS enabled):
--   SELECT policyname, cmd, roles
--   FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'faqs'
--   ORDER BY policyname;

CREATE TABLE IF NOT EXISTS "public"."faqs" (
    "id" "uuid" DEFAULT gen_random_uuid() NOT NULL,
    "slug" "text" NOT NULL,
    "locale" "text" NOT NULL DEFAULT 'en',
    "category_slug" "text" NOT NULL,
    "category_title" "text" NOT NULL,
    "question" "text" NOT NULL,
    "answer_markdown" "text" NOT NULL,
    "sort_order" "integer" NOT NULL DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT "faqs_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "faqs_slug_locale_key" UNIQUE ("slug", "locale"),
    CONSTRAINT "faqs_locale_check"
        CHECK ("locale" IN ('en', 'pt')),
    CONSTRAINT "faqs_slugs_check"
        CHECK (
            char_length(btrim("slug")) > 0
            AND char_length(btrim("category_slug")) > 0
        ),
    CONSTRAINT "faqs_content_check"
        CHECK (
            char_length(btrim("category_title")) > 0
            AND char_length(btrim("question")) > 0
            AND char_length(btrim("answer_markdown")) > 0
        )
);

CREATE INDEX IF NOT EXISTS "faqs_locale_order_idx"
    ON "public"."faqs" ("locale", "sort_order");

CREATE INDEX IF NOT EXISTS "faqs_category_idx"
    ON "public"."faqs" ("locale", "category_slug", "sort_order");

-- Keep updated_at fresh on every UPDATE (same moddatetime helper used
-- elsewhere in database_schema.sql).
DROP TRIGGER IF EXISTS "faqs_moddatetime" ON "public"."faqs";
CREATE TRIGGER "faqs_moddatetime"
    BEFORE UPDATE ON "public"."faqs"
    FOR EACH ROW
    EXECUTE FUNCTION "public"."moddatetime"('updated_at');

ALTER TABLE "public"."faqs" ENABLE ROW LEVEL SECURITY;

-- Public read-only access: the Help & FAQ screen is browsable as a guest,
-- so both anon and authenticated roles can SELECT. No INSERT/UPDATE/DELETE
-- policies are created for client roles: writes are service_role-only
-- (service_role bypasses RLS).
DROP POLICY IF EXISTS "faqs_select_public" ON "public"."faqs";
CREATE POLICY "faqs_select_public" ON "public"."faqs"
    FOR SELECT TO "anon", "authenticated"
    USING (true);

GRANT SELECT ON TABLE "public"."faqs" TO "anon";
GRANT SELECT ON TABLE "public"."faqs" TO "authenticated";
GRANT ALL ON TABLE "public"."faqs" TO "service_role";
