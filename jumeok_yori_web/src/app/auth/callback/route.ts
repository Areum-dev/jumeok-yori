import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

/**
 * 이메일 인증 / 비밀번호 재설정 링크가 최종적으로 도달하는 콜백.
 * Supabase가 PKCE `code` 를 붙여 리디렉션하면 세션으로 교환합니다.
 * Supabase Dashboard > Authentication > URL Configuration > Redirect URLs 에
 * "{배포주소}/auth/callback" 을 반드시 추가해야 합니다.
 */
export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const next = searchParams.get("next") ?? "/";

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      return NextResponse.redirect(`${origin}${next}`);
    }
  }

  return NextResponse.redirect(`${origin}/login?error=인증 처리 중 오류가 발생했습니다`);
}
