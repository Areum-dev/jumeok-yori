import { createClient as createSupabaseClient } from "@supabase/supabase-js";

/**
 * service role 클라이언트. 절대 브라우저에 노출하지 마세요.
 * 서버 전용 코드(API 라우트, 서버 액션)에서만 import 하세요.
 * RLS를 우회하므로 사용 전 반드시 호출자의 인증/권한을 직접 검증해야 합니다.
 */
export function createAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !serviceKey) {
    throw new Error(
      "SUPABASE_SERVICE_ROLE_KEY가 설정되지 않았습니다. 서버 환경변수를 확인하세요.",
    );
  }
  return createSupabaseClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}
