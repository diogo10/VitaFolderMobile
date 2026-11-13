# SQL scripts

All scripts in this folder target the `public` schema of the linked Supabase
project (`VitaFolderMobileBackend`, ref `jheqalwrnztavzxjsdcj`). Files are
grouped into one folder per domain (table family) so that each schema change
lives next to the objects it owns.

Run a script with:

```bash
supabase link --project-ref jheqalwrnztavzxjsdcj
supabase db query --linked --file sqls/<domain>/<file>.sql
```

The FAQ scripts are also mirrored as versioned migrations under
`supabase/migrations/`; prefer `supabase db push` for those and keep both
copies in sync.

## Layout

| Folder       | Owns                                                              |
| ------------ | ----------------------------------------------------------------- |
| `core/`      | Shared `public` objects: full schema snapshot, triggers, functions, teardown |
| `families/`  | `public.families` policies                                        |
| `reminders/` | `public.reminders` constraints and policies                       |
| `notes/`     | `public.notes` table, constraints, and policies                    |
| `faq/`       | `public.faqs` table, policies, and seed content                    |

## Files

### core

- `database_schema.sql` — pg_dump-style snapshot of the whole `public` schema
  (`families`, `family_memberships`, `notification_logs`, `notification_tokens`,
  `profiles`, `reminders`) including RLS, policies, functions, triggers, and
  grants.
- `database_functions.sql` — profile RLS plus the auth-sync triggers
  (`handle_new_user`, `handle_updated_user`, `update_user_metadata`) and the
  shared `moddatetime()` helper.
- `fix_moddatetime.sql` — idempotent `CREATE OR REPLACE` fix for the broken
  `moddatetime()` trigger helper.
- `remove_all.sql` — destructive teardown that drops every table in `public`.
  Local/reset use only.

### families

- `policies.sql` — `families` SELECT policy limiting rows to the creator.

### reminders

- `allow_yearly_repeat_rule.sql` — idempotently drops any `repeat_rule` CHECK
  constraint on `public.reminders` so `yearly` is accepted.
- `family_members_edit_reminders.sql` — family-member UPDATE/DELETE policies
  for `public.reminders`.

### notes

- `notes_schema.sql` — `public.notes` table, color/length CHECK constraints,
  family-member RLS policies, and grants.
- `notes_family_policies.sql` — idempotently (re)applies the four
  `notes_*_member` policies without touching the table definition.

### faq

- `faq_schema.sql` — `public.faqs` table and public read-only RLS.
- `faq_policy.sql` — public read policies and grants for `public.faqs`,
  extracted so they can be re-applied without the table definition.
- `faq_seed.sql` — idempotent, transactional seed of the FAQ content that
  mirrors `docs/faq/README.md`.
