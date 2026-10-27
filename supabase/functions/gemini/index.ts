// Sawki English : intermédiaire entre l'application et l'API Gemini.
//
// La clé Gemini reste sur le serveur (secret GEMINI_API_KEY) et n'est jamais
// envoyée au téléphone. Chaque appel exige une session Supabase valide et
// consomme un crédit dans la limite quotidienne de l'utilisateur.
//
// Requête (POST, JSON) :
//   { "mode": "chat", "message": "...", "level": "B1", "history": [{ "role": "user"|"model", "text": "..." }] }
//   { "mode": "tts",  "text": "..." }
// Réponse :
//   chat → l'objet JSON du tuteur (reply_en, has_error, ...)
//   tts  → { "audio": "<PCM 16 bits 24 kHz en base64>" }
//   429  → { "error": "daily_limit" } quand la limite du jour est atteinte

import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const CHAT_MODELS = (Deno.env.get("GEMINI_CHAT_MODELS") ?? "gemini-3.6-flash,gemini-flash-latest")
  .split(",").map((m) => m.trim()).filter(Boolean);
const TTS_MODEL = Deno.env.get("GEMINI_TTS_MODEL") ?? "gemini-2.5-flash-preview-tts";
const TTS_VOICE = Deno.env.get("GEMINI_TTS_VOICE") ?? "Aoede";

const LIMITS = {
  chat: { free: intEnv("CHAT_DAILY_LIMIT", 30), premium: intEnv("CHAT_DAILY_LIMIT_PREMIUM", 200) },
  tts: { free: intEnv("TTS_DAILY_LIMIT", 100), premium: intEnv("TTS_DAILY_LIMIT_PREMIUM", 400) },
};

const MAX_MESSAGE_CHARS = 1000;
const MAX_TTS_CHARS = 600;
const LEVELS = new Set(["A0", "A1", "A2", "B1", "B2", "C1"]);

function intEnv(name: string, fallback: number): number {
  const v = Number.parseInt(Deno.env.get(name) ?? "", 10);
  return Number.isFinite(v) && v > 0 ? v : fallback;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

function systemInstruction(level: string): string {
  return `
You are "Sarah", a warm, witty, enthusiastic American English coach from Chicago teaching French speakers.
The student's level is CEFR: ${level}.

CORE TEACHING INSTRUCTIONS:
1. Speak in natural, modern American English (idiomatic, friendly, upbeat).
2. CRITICAL BILINGUAL RULE: When the student speaks in French, asks for a translation, asks for clarification, or says they did not understand (e.g. "peux-tu traduire ?", "je n'ai pas compris", "c'est trop lourd", "en français svp"), YOU MUST reply in FRENCH to translate, explain clearly, and encourage them! Then give the easy American English equivalent to practice and end with a friendly question.
3. SPELLING, GRAMMAR & PRONUNCIATION CORRECTIONS:
   - Carefully check the student's message for English spelling typos (e.g. "watter", "alot", "wich"), grammar issues ("I am agree", "he don't"), syntax errors, and phonetic misunderstandings.
   - Whenever an error is present, set "has_error": true, provide "original_segment", "corrected_segment", "error_type", and "explanation_fr".
4. Stay on the topic of learning English. Politely decline other requests.
5. Return your output STRICTLY as a single JSON object with these keys:
{
  "reply_en": "Your conversational reply. If the user asked in French or needed clarification, explain in FRENCH first then give the English phrase and a question. Otherwise, conversational American English (2-3 sentences max).",
  "has_error": true/false,
  "original_segment": "the exact error if any",
  "corrected_segment": "natural American equivalent",
  "error_type": "grammar" | "vocabulary" | "syntax" | "spelling" | "pronunciation" | "idiom",
  "explanation_fr": "Encouraging rule explanation or translation in FRENCH (2-3 sentences max).",
  "tip": "Short memorable tip for French speakers.",
  "american_variant": "American nuance note (e.g., Flap T, gonna, wanna, sidewalk)."
}
`;
}

type Turn = { role: "user" | "model"; parts: { text: string }[] };

// Garde les 4 derniers échanges, en alternant strictement user / model.
function buildContents(history: unknown, message: string): Turn[] {
  const contents: Turn[] = [];
  const items = Array.isArray(history) ? history.slice(-4) : [];
  for (const item of items) {
    const role = item?.role === "user" ? "user" : "model";
    const text = String(item?.text ?? "").trim().slice(0, MAX_MESSAGE_CHARS);
    if (!text) continue;
    if (contents.length === 0 && role !== "user") continue;
    const last = contents[contents.length - 1];
    if (last && last.role === role) last.parts.push({ text });
    else contents.push({ role, parts: [{ text }] });
  }
  const last = contents[contents.length - 1];
  if (last && last.role === "user") last.parts.push({ text: message });
  else contents.push({ role: "user", parts: [{ text: message }] });
  return contents;
}

function cleanJson(raw: string): string {
  let s = raw.trim();
  if (s.startsWith("```json")) s = s.slice(7);
  else if (s.startsWith("```")) s = s.slice(3);
  if (s.endsWith("```")) s = s.slice(0, -3);
  return s.trim();
}

async function callGemini(model: string, body: unknown): Promise<any | null> {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": GEMINI_API_KEY },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(15000),
    },
  );
  if (!res.ok) {
    console.error(`Gemini ${model} → ${res.status}: ${(await res.text()).slice(0, 300)}`);
    return null;
  }
  return await res.json();
}

async function handleChat(payload: any): Promise<Response> {
  const message = String(payload?.message ?? "").trim().slice(0, MAX_MESSAGE_CHARS);
  if (!message) return json({ error: "empty_message" }, 400);
  const level = LEVELS.has(String(payload?.level).toUpperCase())
    ? String(payload.level).toUpperCase()
    : "A1";

  const body = {
    contents: buildContents(payload?.history, message),
    systemInstruction: { parts: [{ text: systemInstruction(level) }] },
    generationConfig: { temperature: 0.7, responseMimeType: "application/json", maxOutputTokens: 350 },
  };

  for (const model of CHAT_MODELS) {
    try {
      const data = await callGemini(model, body);
      const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (typeof text === "string") return json(JSON.parse(cleanJson(text)));
    } catch (e) {
      console.error(`Gemini ${model} exception: ${e}`);
    }
  }
  return json({ error: "upstream_unavailable" }, 502);
}

async function handleTts(payload: any): Promise<Response> {
  const text = String(payload?.text ?? "").trim().slice(0, MAX_TTS_CHARS);
  if (!text) return json({ error: "empty_text" }, 400);
  const body = {
    contents: [{ parts: [{ text }] }],
    generationConfig: {
      responseModalities: ["AUDIO"],
      speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: TTS_VOICE } } },
    },
  };
  try {
    const data = await callGemini(TTS_MODEL, body);
    const audio = data?.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
    if (typeof audio === "string" && audio) return json({ audio });
  } catch (e) {
    console.error(`Gemini TTS exception: ${e}`);
  }
  return json({ error: "upstream_unavailable" }, 502);
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  if (!GEMINI_API_KEY) return json({ error: "server_not_configured" }, 500);

  // 1. Identifier l'utilisateur à partir de sa session Supabase.
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  const user = userData?.user;
  if (userError || !user) return json({ error: "unauthorized" }, 401);

  let payload: any;
  try {
    payload = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }
  const mode = payload?.mode === "tts" ? "tts" : "chat";

  // 2. Vérifier la limite quotidienne (Premium lu côté serveur uniquement).
  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const { data: profile } = await admin
    .from("user_profiles").select("is_premium").eq("user_id", user.id).maybeSingle();
  const limit = profile?.is_premium ? LIMITS[mode].premium : LIMITS[mode].free;
  const { data: allowed, error: quotaError } = await admin.rpc("consume_ai_credit", {
    p_user: user.id,
    p_kind: mode,
    p_limit: limit,
  });
  if (quotaError) {
    console.error(`Quota error: ${quotaError.message}`);
    return json({ error: "quota_unavailable" }, 500);
  }
  if (!allowed) return json({ error: "daily_limit" }, 429);

  // 3. Appeler Gemini.
  return mode === "tts" ? await handleTts(payload) : await handleChat(payload);
});
