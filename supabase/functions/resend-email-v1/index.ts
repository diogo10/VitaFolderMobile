// Supabase Edge Function: resend-email-v1
//
// Sends the HouseMira family-invite email via the Resend API.
// Called by `EdgetFunctions.sendEmail` in
// `lib/core/functions/edget_functions.dart` (see README "Supabase Edge Functions").
//
// Auth: caller JWT verified by `withSupabase({ auth: 'user' })` —
// unauthenticated callers never reach the handler.
// Requires RESEND_API_KEY as a function secret.
//
// Request body:
//   { to: string, locale?: string,
//     inviterName?: string, familyName?: string, inviteCode?: string }
// `locale` accepts 'en'/'pt' (prefix-matched, so 'pt-BR' -> 'pt');
// missing or unsupported values fall back to 'en'.
// Subject and HTML are rendered server-side from the locale and invite data.
// The CTA points at the web join page with the family code appended:
//   https://vitafolder-web-page-nextjs.vercel.app/join-family?invite=<code>
//
// Responses:
//   200 { success: true, id }          — email accepted by Resend
//   400 { code: 'invalid_payload' }    — missing/invalid to (or bad optionals)
//   400 { code: 'invalid_json' }       — body is not JSON
//   401                                — handled by withSupabase (no valid JWT)
//   405 { code: 'method_not_allowed' } — not POST
//   500 { code: 'missing_secret' }     — RESEND_API_KEY not set
//   502 { code: 'resend_failed', ... } — Resend API returned non-2xx

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "jsr:@supabase/server@^1";

const JOIN_BASE_URL =
  "https://vitafolder-web-page-nextjs.vercel.app/join-family";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function json(body: unknown, status: number): Response {
  return Response.json(body, {
    status,
    headers: corsHeaders,
  });
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

type Locale = "en" | "pt";

function resolveLocale(raw: unknown): Locale {
  if (typeof raw !== "string") return "en";
  const prefix = raw.toLowerCase().split(/[-_]/)[0];
  return prefix === "pt" ? "pt" : "en";
}

function optionalText(raw: unknown): string | undefined {
  if (typeof raw !== "string") return undefined;
  const trimmed = raw.trim();
  return trimmed === "" ? undefined : trimmed;
}

interface InviteCopy {
  subject: string;
  preheader: string;
  headline: string;
  intro: string;
  cta: string;
  fallbackLabel: string;
  footer: string;
}

function inviteCopy(
  locale: Locale,
  inviterName: string | undefined,
  familyName: string | undefined,
): InviteCopy {
  if (locale === "pt") {
    const subject = inviterName && familyName
      ? `${inviterName} convidou você para a família ${familyName} no HouseMira`
      : inviterName
      ? `${inviterName} convidou você para o HouseMira`
      : "Você foi convidado para o HouseMira";
    const headline = familyName
      ? `Junte-se à ${familyName} no HouseMira`
      : "Você foi convidado para o HouseMira";
    const intro = inviterName && familyName
      ? `${inviterName} convidou você para participar do círculo familiar ${familyName}. Gerenciem lembretes, tarefas e compromissos juntos — tudo em um só lugar.`
      : inviterName
      ? `${inviterName} convidou você para participar do HouseMira. Gerenciem lembretes, tarefas e compromissos em família — tudo em um só lugar.`
      : "Você foi convidado para participar do HouseMira. Gerencie seu círculo familiar, defina lembretes e colabore em família — tudo em um só lugar.";
    return {
      subject,
      preheader: "Toque no botão para aceitar o convite da sua família.",
      headline,
      intro,
      cta: "Entrar para a família",
      fallbackLabel:
        "Se o botão não funcionar, copie e cole este link no navegador:",
      footer:
        "Se você não esperava este email, pode ignorá-lo com segurança.",
    };
  }
  const subject = inviterName && familyName
    ? `${inviterName} invited you to join ${familyName} on HouseMira`
    : inviterName
    ? `${inviterName} invited you to HouseMira`
    : "You've been invited to HouseMira";
  const headline = familyName
    ? `Join ${familyName} on HouseMira`
    : "You've been invited to HouseMira";
  const intro = inviterName && familyName
    ? `${inviterName} invited you to join the ${familyName} family circle. Manage reminders, chores and appointments together — all in one place.`
    : inviterName
    ? `${inviterName} invited you to join HouseMira. Manage reminders, chores and appointments as a family — all in one place.`
    : "You've been invited to join HouseMira. Manage your family circle, set reminders and collaborate as a family — all in one place.";
  return {
    subject,
    preheader: "Tap the button below to accept your family invitation.",
    headline,
    intro,
    cta: "Join your family",
    fallbackLabel: "If the button doesn't work, copy and paste this link:",
    footer: "If you weren't expecting this email, you can safely ignore it.",
  };
}

function renderHtml(copy: InviteCopy, joinUrl: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>${escapeHtml(copy.subject)}</title>
</head>
<body style="margin:0;padding:0;background-color:#FAF8F5;">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;">${escapeHtml(copy.preheader)}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#FAF8F5;padding:32px 16px;">
<tr><td align="center">
<table role="presentation" width="560" cellpadding="0" cellspacing="0" style="max-width:560px;width:100%;background-color:#FFFFFF;border:1px solid #E4DACE;border-radius:16px;overflow:hidden;">
<tr><td style="padding:32px 32px 8px;text-align:center;font-family:Figtree,Outfit,Helvetica,Arial,sans-serif;font-size:22px;font-weight:700;color:#634F39;">HouseMira</td></tr>
<tr><td style="padding:8px 32px 0;text-align:center;font-family:Figtree,Outfit,Helvetica,Arial,sans-serif;font-size:20px;font-weight:700;color:#634F39;">${escapeHtml(copy.headline)}</td></tr>
<tr><td style="padding:16px 32px 0;font-family:Figtree,Outfit,Helvetica,Arial,sans-serif;font-size:15px;line-height:1.6;color:#7A6348;">${escapeHtml(copy.intro)}</td></tr>
<tr><td align="center" style="padding:28px 32px 8px;">
<a href="${escapeHtml(joinUrl)}" style="display:inline-block;background-color:#C2B299;color:#000000;font-family:Figtree,Outfit,Helvetica,Arial,sans-serif;font-size:16px;font-weight:700;text-decoration:none;padding:14px 32px;border-radius:12px;">${escapeHtml(copy.cta)}</a>
</td></tr>
<tr><td style="padding:16px 32px 0;font-family:Figtree,Outfit,Helvetica,Arial,sans-serif;font-size:13px;line-height:1.6;color:#B8A080;">${escapeHtml(copy.fallbackLabel)}<br /><a href="${escapeHtml(joinUrl)}" style="color:#2B72AD;word-break:break-all;">${escapeHtml(joinUrl)}</a></td></tr>
<tr><td style="padding:24px 32px 32px;font-family:Figtree,Outfit,Helvetica,Arial,sans-serif;font-size:12px;line-height:1.6;color:#B8A080;text-align:center;">${escapeHtml(copy.footer)}</td></tr>
</table>
</td></tr>
</table>
</div>
</body>
</html>`;
}

export default {
  fetch: withSupabase({ auth: "user" }, async (req, _ctx) => {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }
    if (req.method !== "POST") {
      return json({ code: "method_not_allowed" }, 405);
    }

    const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
    if (!RESEND_API_KEY) {
      console.error("resend-email-v1: RESEND_API_KEY secret is not set");
      return json({ code: "missing_secret" }, 500);
    }

    let payload: unknown;
    try {
      payload = await req.json();
    } catch {
      return json({ code: "invalid_json" }, 400);
    }

    const body = (payload ?? {}) as {
      to?: unknown;
      locale?: unknown;
      inviterName?: unknown;
      familyName?: unknown;
      inviteCode?: unknown;
    };
    const to = typeof body.to === "string" ? body.to.trim() : "";
    if (!emailPattern.test(to)) {
      return json({ code: "invalid_payload" }, 400);
    }
    for (const key of ["inviterName", "familyName", "inviteCode"] as const) {
      const value = body[key];
      if (value !== undefined && typeof value !== "string") {
        return json({ code: "invalid_payload" }, 400);
      }
    }

    const locale = resolveLocale(body.locale);
    const inviterName = optionalText(body.inviterName);
    const familyName = optionalText(body.familyName);
    const inviteCode = optionalText(body.inviteCode);

    const copy = inviteCopy(locale, inviterName, familyName);
    const joinUrl = inviteCode
      ? `${JOIN_BASE_URL}?invite=${encodeURIComponent(inviteCode)}`
      : JOIN_BASE_URL;
    const html = renderHtml(copy, joinUrl);

    let res: Response;
    try {
      res = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${RESEND_API_KEY}`,
        },
        body: JSON.stringify({
          from: "no-reply@vitafolder.com",
          to,
          subject: copy.subject,
          html,
        }),
      });
    } catch (error) {
      console.error("resend-email-v1: resend request failed", error);
      return json({ code: "resend_failed" }, 502);
    }

    let data: unknown = null;
    try {
      data = await res.json();
    } catch {
      // Resend always returns JSON, but tolerate an empty/unparseable body.
    }

    if (!res.ok) {
      console.error("resend-email-v1: resend rejected the request", data);
      return json({ code: "resend_failed", detail: data }, 502);
    }

    const id = (data as { id?: unknown } | null)?.id;
    return json({ success: true, id }, 200);
  }),
};
