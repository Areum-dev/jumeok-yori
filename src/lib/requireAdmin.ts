import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import type { Profile } from "@/types/database";

/**
 * 관리자 전용 서버 컴포넌트에서 호출. 세션과 DB profiles.role 을 직접 확인하므로
 * 클라이언트 화면 숨김에만 의존하지 않습니다. (실제 데이터 접근은 RLS is_admin() 이 최종 방어선)
 */
export async function requireAdmin() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login?error=" + encodeURIComponent("관리자만 접근할 수 있습니다."));

  const { data: profile } = await supabase.from("profiles").select("*").eq("id", user.id).maybeSingle();
  if ((profile as Profile | null)?.role !== "admin") {
    redirect("/");
  }

  return { supabase, user, profile: profile as Profile };
}
