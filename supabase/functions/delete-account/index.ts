// Supabase Edge Function: delete-account
//
// Deletes the caller's auth user (auth.admin.deleteUser). Postgres
// ON DELETE CASCADE then removes `profiles`, `family_memberships`,
// `notification_tokens` and `notification_logs` rows. The `families`
// row itself is left intact (`created_by` is SET NULL) so other
// members keep their data.
//
// Blocked when the caller is the sole remaining member of a family
// they own: returns 409 { code: 'sole_owner', family_id } and deletes
// nothing, so the client can point the user at Family Settings.
//
// Auth: caller JWT in the Authorization header. The uid is always taken
// from the verified token, never from the request body.
// Requires SUPABASE_URL, SUPABASE_ANON_KEY (JWT verification) and
// SUPABASE_SERVICE_ROLE_KEY (admin delete) as function secrets.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

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
  if (!jwt) {
    return json({ code: 'unauthorized' }, 401);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  // Verify the caller with their own JWT.
  const caller = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userError } = await caller.auth.getUser(jwt);
  const userId = userData?.user?.id;
  if (userError || !userId) {
    return json({ code: 'unauthorized' }, 401);
  }

  // Privileged client for membership checks + admin delete.
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  // Sole-owner guard: families where the caller is owner.
  const { data: owned, error: ownedError } = await admin
    .from('family_memberships')
    .select('family_id')
    .eq('user_id', userId)
    .eq('role', 'owner');
  if (ownedError) {
    console.error('delete-account: owned lookup failed', ownedError);
    return json({ code: 'lookup_failed' }, 500);
  }
  for (const row of owned ?? []) {
    const { count, error: countError } = await admin
      .from('family_memberships')
      .select('id', { count: 'exact', head: true })
      .eq('family_id', (row as { family_id: string }).family_id);
    if (countError) {
      console.error('delete-account: member count failed', countError);
      return json({ code: 'lookup_failed' }, 500);
    }
    if ((count ?? 0) <= 1) {
      return json(
        {
          code: 'sole_owner',
          family_id: (row as { family_id: string }).family_id,
        },
        409,
      );
    }
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
  if (deleteError) {
    console.error('delete-account: admin.deleteUser failed', deleteError);
    return json({ code: 'delete_failed' }, 500);
  }

  return json({ success: true }, 200);
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
