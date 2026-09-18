# Supabase

Project: `VitaFolderMobileBackend`. Client: `supabase_flutter`.
Full skill: `.agents/skills/supabase/SKILL.md` (read before schema/auth work).

## Client usage

- Production code uses the injected `SupabaseClient`
  (`Supabase.instance.client` as default); tests inject mocks.
- Auth flows live in `lib/core/auth/auth_service.dart`
  (email, Google ID-token exchange, reset, sign-out, delete).
  UID always comes from the verified session server-side, never from input.
- Data access lives in `data/` repositories; map errors to `Failure`.
  Cast dynamic rows explicitly: `(e as Map<String, dynamic>)['col'] as String`.

## Edge functions

Source: `supabase/functions/<name>/index.ts` (Deno). Documented in
`README.md` ("Supabase Edge Functions"): currently `delete-account`
(sole-owner guard, response codes, secrets, deploy commands).
When adding a function: add the code, its secrets, deploy steps, client
call site, and tests — and extend the README section the same way.

## Local dev

```bash
supabase link --project-ref <ref>
supabase functions serve <name>      # local serve
supabase functions deploy <name>     # deploy
supabase secrets set KEY=value       # function secrets
```

Never expose `service_role`/secret keys in client code. After any RLS,
policy, view, or function change, run advisors and re-check the
security checklist in the Supabase skill.
