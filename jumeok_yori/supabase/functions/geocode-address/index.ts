import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, "Content-Type": "application/json" },
});

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ success: false, error: "Method not allowed" }, 405);

  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return json({ success: false, error: "Authentication required" }, 401);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const clientId = Deno.env.get("NAVER_MAP_CLIENT_ID");
  const clientSecret = Deno.env.get("NAVER_MAP_CLIENT_SECRET");
  if (!supabaseUrl || !anonKey || !clientId || !clientSecret) {
    return json({ success: false, error: "Server configuration error" }, 500);
  }

  const caller = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data, error } = await caller.auth.getUser(token);
  if (error || !data.user) return json({ success: false, error: "Invalid session" }, 401);

  let body: { address?: unknown };
  try { body = await req.json(); } catch { return json({ success: false, error: "Invalid JSON" }, 400); }
  const address = typeof body.address === "string" ? body.address.trim() : "";
  if (address.length < 2 || address.length > 200) {
    return json({ success: false, error: "주소는 2자 이상 200자 이하로 입력해 주세요." }, 400);
  }

  const url = new URL("https://maps.apigw.ntruss.com/map-geocode/v2/geocode");
  url.searchParams.set("query", address);
  const response = await fetch(url, { headers: {
    "X-NCP-APIGW-API-KEY-ID": clientId,
    "X-NCP-APIGW-API-KEY": clientSecret,
  }});
  if (!response.ok) return json({ success: false, error: "Geocoding provider error" }, 502);

  const payload = await response.json();
  const first = Array.isArray(payload?.addresses) ? payload.addresses[0] : null;
  const lat = Number(first?.y);
  const lng = Number(first?.x);
  if (!first || !Number.isFinite(lat) || !Number.isFinite(lng)) {
    return json({ success: false, error: "주소를 찾을 수 없어요." }, 404);
  }
  return json({ success: true, lat, lng, roadAddress: first.roadAddress ?? null, jibunAddress: first.jibunAddress ?? null });
});
