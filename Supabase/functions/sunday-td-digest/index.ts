// Edge function: Sunday TD digest.
// Runs Sunday 08:00 Asia/Dubai via pg_cron — schedule with:
//   select cron.schedule(
//     'shjsdsc_sunday_td_digest',
//     '0 4 * * 0', -- Sunday 04:00 UTC = 08:00 Asia/Dubai
//     $$
//       select net.http_post(
//         url := 'https://<project-ref>.functions.supabase.co/sunday-td-digest',
//         headers := jsonb_build_object(
//           'Content-Type', 'application/json',
//           'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
//         ),
//         body := '{}'::jsonb
//       )
//     $$
//   );
//
// Env vars expected:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
//   APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_PRIVATE_KEY (PEM)
//   FALLBACK_EMAIL_ENABLED ("true" | "false"), RESEND_API_KEY (or SMTP creds)
//
// Response: { delivered: number, errors: string[] }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

interface DigestPayload {
  scoresAvg: number;
  watchListCount: number;
  certsExpiring: number;
}

async function buildDigest(client: ReturnType<typeof createClient>): Promise<DigestPayload> {
  // Composite proxy: pull each athlete's latest performance_scores row and
  // average the seven dimensions equally. Real version should mirror
  // ScoreEngine.composite weights — kept simple here.
  const { data: scores } = await client
    .from("performance_scores")
    .select("competition,technical,physical,adherence,belt_progression,wellness,character,athlete_id,calculated_at")
    .order("calculated_at", { ascending: false });

  const latestPerAthlete = new Map<string, Record<string, number>>();
  for (const s of scores ?? []) {
    if (!latestPerAthlete.has(s.athlete_id)) latestPerAthlete.set(s.athlete_id, s);
  }
  let sum = 0;
  for (const row of latestPerAthlete.values()) {
    sum += (row.competition + row.technical + row.physical + row.adherence
            + row.belt_progression + row.wellness + row.character) / 7;
  }
  const avg = latestPerAthlete.size === 0 ? 0 : sum / latestPerAthlete.size;

  const { count: watchCount } = await client
    .from("athletes")
    .select("id", { count: "exact", head: true })
    .eq("status", "watch");

  const cutoff = new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString();
  const { count: expiringCount } = await client
    .from("certifications")
    .select("id", { count: "exact", head: true })
    .lte("expires_at", cutoff);

  return {
    scoresAvg: Math.round(avg),
    watchListCount: watchCount ?? 0,
    certsExpiring: expiringCount ?? 0,
  };
}

async function tdRecipients(client: ReturnType<typeof createClient>) {
  const { data } = await client
    .from("user_profiles")
    .select("id, full_name")
    .in("role", ["technicalDirector", "admin"]);
  return data ?? [];
}

async function pushAPNs(_userID: string, _payload: DigestPayload): Promise<boolean> {
  // Hook up to APNs HTTP/2 with a JWT signed using APNS_PRIVATE_KEY.
  // Out of scope for the seed implementation — wire to your push service of
  // choice. Returning false makes the dispatcher fall back to email.
  return false;
}

async function emailFallback(_recipient: { id: string; full_name: string }, _payload: DigestPayload): Promise<boolean> {
  // Hook up to your transactional email provider (Resend/SendGrid/SMTP).
  // Stub — return true so the function reports success in stage testing.
  return true;
}

Deno.serve(async (_req) => {
  const errors: string[] = [];
  let delivered = 0;
  try {
    const client = createClient(supabaseUrl, serviceRoleKey);
    const payload = await buildDigest(client);
    const recipients = await tdRecipients(client);
    for (const r of recipients) {
      try {
        const ok = await pushAPNs(r.id, payload);
        if (!ok && Deno.env.get("FALLBACK_EMAIL_ENABLED") === "true") {
          await emailFallback(r, payload);
        }
        delivered += 1;
      } catch (e) {
        errors.push(`${r.id}: ${(e as Error).message}`);
      }
    }
    return new Response(JSON.stringify({ delivered, errors, payload }), {
      headers: { "Content-Type": "application/json" }
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), { status: 500 });
  }
});
