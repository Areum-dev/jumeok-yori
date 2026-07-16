"use client";

import { useEffect, useState, useCallback } from "react";
import { createClient } from "@/lib/supabase/client";
import { useAuth } from "@/components/AuthProvider";
import { useLocation } from "@/hooks/useLocation";
import { LocationPicker } from "@/components/LocationPicker";
import { FilterPanel } from "@/components/FilterPanel";
import { RecommendationCard } from "@/components/RecommendationCard";
import {
  recommend as runRecommend,
  defaultFilter,
  resultId,
  type RecommendationFilter,
  type RecommendationResult,
} from "@/lib/recommend";
import type { MenuItemWithRestaurant, StarterMenu } from "@/types/database";
import {
  loadFilter,
  saveFilter,
  getOrCreateAnonymousId,
  getRecentRegisteredIds,
  getRecentStarterIds,
  addRecentRegisteredId,
  addRecentStarterId,
} from "@/lib/localUser";
import { isItemSaved, toggleItemSaved } from "@/lib/savedItems";

export default function RecommendPage() {
  const { user } = useAuth();
  const { location, requesting, permissionError, requestBrowserLocation, setManualLocation } = useLocation();

  const [filter, setFilter] = useState<RecommendationFilter>(defaultFilter);
  const [registeredMenus, setRegisteredMenus] = useState<MenuItemWithRestaurant[]>([]);
  const [starterMenus, setStarterMenus] = useState<StarterMenu[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [result, setResult] = useState<RecommendationResult | null>(null);
  const [noMatch, setNoMatch] = useState(false);
  const [saved, setSaved] = useState(false);
  const [drawing, setDrawing] = useState(false);

  useEffect(() => {
    // localStorage 는 클라이언트에만 있으므로 마운트 후 필터를 불러와 하이드레이션 불일치를 피합니다.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setFilter(loadFilter());
  }, []);

  useEffect(() => {
    let mounted = true;
    async function load() {
      setLoading(true);
      setLoadError(null);
      const supabase = createClient();
      const [menuRes, starterRes] = await Promise.all([
        supabase
          .from("menu_items")
          .select("*, restaurants!inner(*)")
          .eq("approval_status", "approved")
          .eq("display_status", "approved")
          .eq("is_available", true),
        supabase.from("starter_menus").select("*").eq("display_status", "approved"),
      ]);
      if (!mounted) return;
      setRegisteredMenus((menuRes.data as unknown as MenuItemWithRestaurant[]) ?? []);
      setStarterMenus((starterRes.data as StarterMenu[]) ?? []);
      if (menuRes.error && starterRes.error) {
        setLoadError("메뉴 데이터를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.");
      }
      setLoading(false);
    }
    load();
    return () => {
      mounted = false;
    };
  }, []);

  const draw = useCallback(async () => {
    setDrawing(true);
    saveFilter(filter);

    const picked = runRecommend({
      registeredMenus,
      starterMenus,
      filter,
      userLat: location.lat,
      userLng: location.lng,
      recentRegisteredIds: getRecentRegisteredIds(),
      recentStarterIds: getRecentStarterIds(),
    });

    if (!picked) {
      setResult(null);
      setNoMatch(true);
      setDrawing(false);
      return;
    }

    setNoMatch(false);
    setResult(picked);
    const id = resultId(picked);
    if (id) {
      if (picked.type === "registered") addRecentRegisteredId(id);
      else addRecentStarterId(id);
      if (user) {
        isItemSaved(createClient(), user.id, picked.type, id).then(setSaved);
      } else {
        setSaved(false);
      }
    }

    // 추천 기록 저장 (실패해도 무시)
    try {
      const supabase = createClient();
      await supabase.from("recommendation_logs").insert({
        user_id: user?.id ?? null,
        anonymous_user_id: user ? null : getOrCreateAnonymousId(),
        recommendation_type: picked.type,
        menu_item_id: picked.menuItem?.id ?? null,
        starter_menu_id: picked.starterMenu?.id ?? null,
        restaurant_id: picked.menuItem?.restaurant_id ?? null,
        filters_json: filter,
        user_lat: location.lat,
        user_lng: location.lng,
      });
      if (picked.menuItem?.restaurants?.owner_id) {
        await supabase.from("analytics_events").insert({
          event_type: "recommendation_drawn",
          user_id: user?.id ?? null,
          anonymous_user_id: user ? null : getOrCreateAnonymousId(),
          owner_id: picked.menuItem.restaurants.owner_id,
          restaurant_id: picked.menuItem.restaurant_id,
          menu_item_id: picked.menuItem.id,
          recommendation_type: picked.type,
        });
      }
    } catch {
      // 통계/로그 실패는 사용자 경험에 영향 주지 않도록 무시
    }

    setDrawing(false);
  }, [filter, registeredMenus, starterMenus, location, user]);

  async function handleToggleSave() {
    if (!result) return;
    const id = resultId(result);
    if (!id) return;
    if (!user) {
      alert("로그인 후 메뉴를 저장할 수 있어요.");
      return;
    }
    const nowSaved = await toggleItemSaved(createClient(), user.id, result.type, id);
    setSaved(nowSaved);
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-10 sm:px-6">
      <h1 className="text-2xl font-black text-dark-ink sm:text-3xl">오늘 메뉴 뽑기</h1>
      <p className="mt-2 text-sm text-text-gray">기준 위치와 조건을 정하면 오늘 먹을 메뉴를 랜덤으로 골라드려요.</p>

      <div className="mt-6 space-y-4">
        <LocationPicker
          location={location}
          requesting={requesting}
          permissionError={permissionError}
          onRequestBrowserLocation={requestBrowserLocation}
          onManualLocation={setManualLocation}
        />
        <FilterPanel filter={filter} onChange={setFilter} />
      </div>

      {loadError && <p className="mt-4 text-sm font-medium text-error">{loadError}</p>}

      <button
        onClick={draw}
        disabled={loading || drawing}
        className="mt-6 w-full rounded-2xl bg-orange py-4 text-lg font-black text-white shadow-sm transition hover:opacity-90 disabled:opacity-50"
      >
        {loading ? "메뉴 불러오는 중..." : drawing ? "뽑는 중..." : "🎲 오늘 메뉴 뽑기"}
      </button>

      {noMatch && (
        <div className="mt-8 rounded-2xl border border-dashed border-soft-gray bg-white p-8 text-center">
          <p className="text-base font-bold text-dark-ink">조건에 맞는 메뉴를 찾지 못했어요.</p>
          <p className="mt-2 text-sm text-text-gray">거리나 가격 조건을 조금 넓혀서 다시 시도해보세요.</p>
        </div>
      )}

      {result && (
        <div className="mt-8">
          <RecommendationCard result={result} saved={saved} onToggleSave={handleToggleSave} onRedraw={draw} />
        </div>
      )}
    </div>
  );
}
