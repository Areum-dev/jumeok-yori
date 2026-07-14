import type { SupabaseClient } from "@supabase/supabase-js";
import type { RecommendationResultType } from "@/lib/recommend";

/**
 * 저장(찜) 기능. Flutter 앱은 로컬(shared_preferences)에만 저장하지만,
 * 웹은 saved_menu_items 테이블(schema.sql 에 이미 정의됨, RLS 로 본인 소유만 접근 가능)을
 * 사용해 로그인 계정 기준으로 저장합니다. 향후 앱도 같은 테이블을 사용하면 완전히 동기화됩니다.
 */
export async function isItemSaved(
  supabase: SupabaseClient,
  userId: string,
  type: RecommendationResultType,
  id: string,
): Promise<boolean> {
  const column = type === "registered" ? "menu_item_id" : "starter_menu_id";
  const { data } = await supabase
    .from("saved_menu_items")
    .select("id")
    .eq("user_id", userId)
    .eq(column, id)
    .maybeSingle();
  return Boolean(data);
}

/** 저장 토글. 저장되어 있으면 삭제, 없으면 추가. 반환값은 토글 후 저장 상태. */
export async function toggleItemSaved(
  supabase: SupabaseClient,
  userId: string,
  type: RecommendationResultType,
  id: string,
): Promise<boolean> {
  const column = type === "registered" ? "menu_item_id" : "starter_menu_id";
  const already = await isItemSaved(supabase, userId, type, id);

  if (already) {
    await supabase.from("saved_menu_items").delete().eq("user_id", userId).eq(column, id);
    return false;
  }

  await supabase.from("saved_menu_items").insert({
    user_id: userId,
    recommendation_type: type,
    [column]: id,
  });
  return true;
}
