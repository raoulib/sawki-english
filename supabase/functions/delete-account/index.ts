// Sawki English : suppression définitive du compte de l'utilisateur connecté.
//
// Efface le profil cloud, le compteur d'usage IA et le compte Supabase Auth.
// Exigé par Google Play pour toute app qui permet de créer un compte.

import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const { data, error } = await userClient.auth.getUser();
  const user = data?.user;
  if (error || !user) return json({ error: "unauthorized" }, 401);

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // Les lignes liées (user_profiles, ai_usage) partent aussi grâce à
  // « on delete cascade », mais on les efface explicitement par sécurité.
  await admin.from("user_profiles").delete().eq("user_id", user.id);
  await admin.from("ai_usage").delete().eq("user_id", user.id);

  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) {
    console.error(`deleteUser failed: ${deleteError.message}`);
    return json({ error: "delete_failed" }, 500);
  }
  return json({ deleted: true });
});
