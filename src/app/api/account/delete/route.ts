import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";

/**
 * 로그인한 본인 계정을 실제로 삭제합니다 (비활성화가 아님).
 * service role 은 이 서버 라우트 안에서만 사용되며 클라이언트에는 절대 노출되지 않습니다.
 *
 * 데이터 처리 방침 (무조건 cascade 삭제하지 않고 관계를 검토함):
 * - saved_menu_items(찜)      : 완전 삭제 (순수 개인 데이터, NOT NULL user_id)
 * - recommendation_logs(위치 포함) : 완전 삭제 (개인정보처리방침 "위치 이용 기록은 탈퇴 즉시 삭제" 준수)
 * - reports(신고 기록)         : user_id 만 NULL 처리 (법적 보관 의무 3년, 내용은 보존)
 * - owner_store_applications  : user_id 만 NULL 처리 (심사 이력 보존)
 * - restaurants(소유 가게)     : owner_id NULL + display_status='suspended' (탈퇴 즉시 비공개 처리,
 *                                 다른 이용자의 기존 추천/즐겨찾기 기록을 깨뜨리지 않기 위해 레코드 자체는 유지)
 * - menu_items(소유 메뉴)      : owner_id NULL + display_status='suspended'
 * - analytics_events          : DB 마이그레이션에서 ON DELETE SET NULL 로 자동 처리됨
 * - profiles                  : auth.users 삭제 시 ON DELETE CASCADE 로 자동 삭제됨
 */
export async function POST() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "로그인이 필요합니다." }, { status: 401 });
  }

  let admin;
  try {
    admin = createAdminClient();
  } catch {
    return NextResponse.json(
      { error: "서버 설정 오류로 계정을 삭제할 수 없습니다. 관리자에게 문의해주세요." },
      { status: 500 },
    );
  }

  const userId = user.id;

  try {
    await admin.from("restaurants").update({ owner_id: null, display_status: "suspended" }).eq("owner_id", userId);
    await admin.from("menu_items").update({ owner_id: null, display_status: "suspended" }).eq("owner_id", userId);
    await admin.from("owner_store_applications").update({ user_id: null }).eq("user_id", userId);
    await admin.from("saved_menu_items").delete().eq("user_id", userId);
    await admin.from("recommendation_logs").delete().eq("user_id", userId);
    await admin.from("reports").update({ user_id: null }).eq("user_id", userId);

    const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
    if (deleteError) {
      return NextResponse.json({ error: `계정 삭제 중 오류가 발생했습니다: ${deleteError.message}` }, { status: 500 });
    }
  } catch {
    return NextResponse.json({ error: "계정 삭제 처리 중 오류가 발생했습니다." }, { status: 500 });
  }

  const res = NextResponse.json({ success: true });
  // 남아있을 수 있는 세션 쿠키 정리
  res.cookies.delete("sb-access-token");
  res.cookies.delete("sb-refresh-token");
  return res;
}
