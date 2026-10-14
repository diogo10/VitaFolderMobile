// Supabase Edge Function: join-family-v1
//
// Adds an existing account (by email) to a family (by family code) with
// role `member`. Mirrors the client-side join
// (`PeopleRepositoryImpl.joinFamily`): canonicalize the code, resolve the
// family, idempotently insert the membership, then best-effort insert the
// `people` row.
//
// Auth: two accepted modes.
//
//  1. Owner/admin user: caller JWT in the Authorization header. The uid is
//     always taken from the verified token, never from the request body.
//     The caller must hold role `owner` or `admin` on the target family,
//     otherwise 403.
//  2. Trusted backend: shared secret in the `x-join-secret` header. This
//     covers server-to-server calls (e.g. the housemira.com backend) where
//     no owner JWT is available. The secret is held ONLY by the backend —
//     never ship it in browser JS, the mobile app, or any client: anyone
//     holding it can add any account to any family. A present-but-wrong
//     secret returns 403 without falling through to JWT auth.
//
// RLS is bypassed via the service-role client (the membership INSERT
// policy only permits self-insert), so the checks above are the security
// boundary — do not weaken them. The public SUPABASE_ANON_KEY is never
// accepted as authorization: it is not a secret.
//
// Request body:
//   { email: string, familyCode: string }
// `familyCode` accepts the same input as the app (separators and casing
// are ignored, so `ab-1234` becomes `AB1234`); anything outside the
// canonical `[A-Z0-9]{6}` form is rejected.
// The target email must belong to a registered account with a `profiles`
// row (auth.users FK) — otherwise there is nothing to join.
//
// Responses:
//   200 { success: true, family_id }              — joined (or already a member;
//                                                 `already_member: true` then)
//   400 { code: 'invalid_payload' }               — bad email/code shape
//   400 { code: 'invalid_json' }                  — body is not JSON
//   401 { code: 'unauthorized' }                  — missing/invalid JWT
//   403 { code: 'not_authorized' }                — caller is not owner/admin
//                                                 (or wrong join secret)
//   404 { code: 'family_not_found' }              — no family for the code
//   404 { code: 'unknown_user' }                  — no (fully registered)
//                                                 account for the email
//   405 { code: 'method_not_allowed' }            — not POST
//   500 { code: 'missing_secret' }                — Supabase secret not set
//   500 { code: 'lookup_failed' }                 — family/role/user lookup failed
//   500 { code: 'membership_failed' }             — membership insert failed
//
// Requires SUPABASE_URL, SUPABASE_ANON_KEY (JWT verification) and
// SUPABASE_SERVICE_ROLE_KEY (user lookup + membership write) as secrets.
// Trusted-backend mode additionally requires JOIN_FAMILY_SHARED_SECRET;
// when it is unset, the `x-join-secret` header is always rejected.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const formattingChars = /[\s\-_]/g;
const canonicalCode = /^[A-Z0-9]{6}$/;

function normalizeFamilyCode(raw: string): string {
  return raw.trim().toUpperCase().replace(formattingChars, '');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return json({ code: 'method_not_allowed' }, 405);
  }

  const jwt = (req.headers.get('Authorization') ?? '').replace(
    /^Bearer\s+/i,
    '',
  );

  // Trusted-backend mode: shared secret, server-to-server only.
  const backendSecret = req.headers.get('x-join-secret') ?? '';
  let backendCaller = false;
  if (backendSecret !== '') {
    const expectedSecret = Deno.env.get('JOIN_FAMILY_SHARED_SECRET') ?? '';
    if (expectedSecret === '' ||
        !(await secretsEqual(backendSecret, expectedSecret))) {
      return json({ code: 'not_authorized' }, 403);
    }
    backendCaller = true;
  }
  if (!backendCaller && !jwt) {
    return json({ code: 'unauthorized' }, 401);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    console.error('join-family-v1: Supabase secret is not set');
    return json({ code: 'missing_secret' }, 500);
  }

  // Verify the caller with their own JWT (skipped for trusted backends,
  // which carry no user identity).
  let callerId: string | null = null;
  if (!backendCaller) {
    const caller = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: `Bearer ${jwt}` } },
      auth: { persistSession: false },
    });
    const { data: userData, error: userError } = await caller.auth.getUser(
      jwt,
    );
    callerId = userData?.user?.id ?? null;
    if (userError || !callerId) {
      return json({ code: 'unauthorized' }, 401);
    }
  }

  let payload: unknown;
  try {
    payload = await req.json();
  } catch {
    return json({ code: 'invalid_json' }, 400);
  }

  const body = (payload ?? {}) as { email?: unknown; familyCode?: unknown };
  const email = typeof body.email === 'string' ? body.email.trim() : '';
  const familyCode = typeof body.familyCode === 'string'
    ? normalizeFamilyCode(body.familyCode)
    : '';
  if (!emailPattern.test(email) || !canonicalCode.test(familyCode)) {
    return json({ code: 'invalid_payload' }, 400);
  }

  // Privileged client for lookups + membership write (bypasses RLS).
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: family, error: familyError } = await admin
    .from('families')
    .select('id')
    .eq('invite_code', familyCode)
    .maybeSingle();
  if (familyError) {
    console.error('join-family-v1: family lookup failed', familyError);
    return json({ code: 'lookup_failed' }, 500);
  }
  const familyId = (family as { id?: string } | null)?.id;
  if (!familyId) {
    return json({ code: 'family_not_found' }, 404);
  }

  // Owner/admin check (user-JWT mode only): trusted backends are already
  // authorized by the shared secret.
  if (!backendCaller) {
    const { data: callerMembership, error: roleError } = await admin
      .from('family_memberships')
      .select('role')
      .eq('family_id', familyId)
      .eq('user_id', callerId!)
      .maybeSingle();
    if (roleError) {
      console.error('join-family-v1: caller role lookup failed', roleError);
      return json({ code: 'lookup_failed' }, 500);
    }
    const callerRole =
      (callerMembership as { role?: string } | null)?.role;
    if (callerRole !== 'owner' && callerRole !== 'admin') {
      return json({ code: 'not_authorized' }, 403);
    }
  }

  const targetId = await findUserIdByEmail(admin, email);
  if (targetId === null) {
    return json({ code: 'lookup_failed' }, 500);
  }
  if (!targetId) {
    return json({ code: 'unknown_user' }, 404);
  }

  // The membership FK requires a profiles row: an auth account without one
  // (e.g. interrupted signup) cannot be joined yet.
  const { data: profile, error: profileError } = await admin
    .from('profiles')
    .select('id')
    .eq('id', targetId)
    .maybeSingle();
  if (profileError) {
    console.error('join-family-v1: profile lookup failed', profileError);
    return json({ code: 'lookup_failed' }, 500);
  }
  if (!profile) {
    return json({ code: 'unknown_user' }, 404);
  }

  // Idempotent join: a retry (or a previous attempt that failed after the
  // membership row was written) succeeds instead of surfacing a
  // duplicate-key error.
  if (await isMemberOf(admin, targetId, familyId)) {
    return json({ success: true, already_member: true, family_id: familyId }, 200);
  }
  const { error: insertError } = await admin.from('family_memberships').insert(
    { family_id: familyId, user_id: targetId, role: 'member' },
  );
  if (insertError) {
    // Lost race / duplicate insert: re-check before reporting failure.
    if (await isMemberOf(admin, targetId, familyId)) {
      return json({ success: true, already_member: true, family_id: familyId }, 200);
    }
    console.error('join-family-v1: membership insert failed', insertError);
    return json({ code: 'membership_failed' }, 500);
  }

  // Best-effort people row: a failure here must never report the join
  // itself as failed — the membership above is what makes the user part
  // of the family.
  try {
    const fullName =
      (await fullNameFor(admin, targetId)) ?? '';
    await admin.from('people').insert({
      family_id: familyId,
      full_name: fullName,
    });
  } catch (error) {
    console.error('join-family-v1: non-fatal people insert failed', error);
  }

  return json({ success: true, family_id: familyId }, 200);
});

async function isMemberOf(
  admin: ReturnType<typeof createClient>,
  userId: string,
  familyId: string,
): Promise<boolean> {
  const { data, error } = await admin
    .from('family_memberships')
    .select('family_id')
    .eq('user_id', userId)
    .eq('family_id', familyId)
    .maybeSingle();
  if (error) {
    console.error('join-family-v1: membership check failed', error);
    return false;
  }
  return data !== null;
}

/// Resolves the auth user id for [email] (case-insensitive), or '' when no
/// account uses it. Returns null when the lookup itself fails.
async function findUserIdByEmail(
  admin: ReturnType<typeof createClient>,
  email: string,
): Promise<string | null> {
  const wanted = email.toLowerCase();
  let page = 1;
  for (;;) {
    const { data, error } = await admin.auth.admin.listUsers({
      page,
      perPage: 100,
    });
    if (error) {
      console.error('join-family-v1: user lookup failed', error);
      return null;
    }
    const users = data?.users ?? [];
    const match = users.find(
      (u) => (u.email ?? '').toLowerCase() === wanted,
    );
    if (match) return match.id;
    if (users.length < 100) return '';
    page += 1;
    if (page > 20) {
      console.error('join-family-v1: user lookup exceeded page cap');
      return null;
    }
  }
}

async function fullNameFor(
  admin: ReturnType<typeof createClient>,
  userId: string,
): Promise<string | undefined> {
  const { data, error } = await admin
    .from('profiles')
    .select('full_name')
    .eq('id', userId)
    .maybeSingle();
  if (error) {
    console.error('join-family-v1: full-name lookup failed', error);
    return undefined;
  }
  const name = (data as { full_name?: unknown } | null)?.full_name;
  return typeof name === 'string' && name.trim() !== ''
    ? name.trim()
    : undefined;
}

/// Timing-safe shared-secret comparison: both sides are SHA-256 hashed
/// first so the comparison is constant-time regardless of input length.
async function secretsEqual(provided: string, expected: string): Promise<boolean> {
  const encode = (value: string) =>
    crypto.subtle.digest('SHA-256', new TextEncoder().encode(value));
  const [a, b] = await Promise.all([encode(provided), encode(expected)]);
  return crypto.subtle.timingSafeEqual(new Uint8Array(a), new Uint8Array(b));
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
