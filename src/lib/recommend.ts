import { calculateKm } from "@/lib/distance";
import type { MenuItemWithRestaurant, StarterMenu } from "@/types/database";

export interface RecommendationFilter {
  distanceKm: number; // 0.5 ~ 5.0
  maxPrice: number; // 5000 ~ 30000
  category: string | null; // null 이면 전체
  soloFriendly: boolean;
  takeoutAvailable: boolean;
  deliveryAvailable: boolean;
  veganOption: boolean;
  excludeRecent: boolean;
}

export const defaultFilter: RecommendationFilter = {
  distanceKm: 2.0,
  maxPrice: 15000,
  category: null,
  soloFriendly: false,
  takeoutAvailable: false,
  deliveryAvailable: false,
  veganOption: false,
  excludeRecent: true,
};

export type RecommendationResultType = "registered" | "starter";

export interface RecommendationResult {
  type: RecommendationResultType;
  menuItem?: MenuItemWithRestaurant;
  starterMenu?: StarterMenu;
  distanceKm?: number;
}

export function menuName(r: RecommendationResult): string {
  return r.menuItem?.name ?? r.starterMenu?.name ?? "";
}

export function menuCategory(r: RecommendationResult): string {
  return r.menuItem?.category ?? r.starterMenu?.category ?? "";
}

export function menuImage(r: RecommendationResult): string | null {
  return r.menuItem?.image_url ?? r.starterMenu?.image_url ?? null;
}

export function resultId(r: RecommendationResult): string | null {
  return r.type === "registered" ? r.menuItem?.id ?? null : r.starterMenu?.id ?? null;
}

export function priceText(r: RecommendationResult): string {
  if (r.type === "registered" && r.menuItem) {
    return `${r.menuItem.price.toLocaleString("ko-KR")}원`;
  }
  const s = r.starterMenu;
  if (!s) return "";
  if (s.expected_min_price == null && s.expected_max_price == null) return "가격 정보 없음";
  if (s.expected_min_price != null && s.expected_max_price != null) {
    return `${s.expected_min_price.toLocaleString("ko-KR")} ~ ${s.expected_max_price.toLocaleString("ko-KR")}원`;
  }
  const p = s.expected_min_price ?? s.expected_max_price!;
  return `약 ${p.toLocaleString("ko-KR")}원`;
}

export function conditionTags(r: RecommendationResult): string[] {
  const tags: string[] = [];
  if (r.type === "registered" && r.menuItem) {
    const m = r.menuItem;
    if (m.is_solo_friendly) tags.push("혼밥 OK");
    if (m.is_takeout_available) tags.push("포장 가능");
    if (m.is_delivery_available) tags.push("배달 가능");
    if (m.is_vegan_option) tags.push("비건 옵션");
    if (m.spicy_level != null && m.spicy_level >= 3) tags.push("매운맛");
  } else if (r.starterMenu) {
    const s = r.starterMenu;
    if (s.is_solo_friendly) tags.push("혼밥 OK");
    if (s.is_takeout_friendly) tags.push("포장 추천");
    if (s.is_delivery_friendly) tags.push("배달 추천");
    if (s.is_vegan_option) tags.push("비건 옵션");
  }
  return tags;
}

/**
 * 등록 메뉴 + 스타터(기본) 메뉴를 통합 필터링 후 하나를 무작위 추천합니다.
 * jumeok_yori(Flutter) recommendation_service.dart 와 동일 로직을 유지합니다.
 */
export function recommend(params: {
  registeredMenus: MenuItemWithRestaurant[];
  starterMenus: StarterMenu[];
  filter: RecommendationFilter;
  userLat: number;
  userLng: number;
  recentRegisteredIds?: string[];
  recentStarterIds?: string[];
}): RecommendationResult | null {
  const {
    registeredMenus,
    starterMenus,
    filter,
    userLat,
    userLng,
    recentRegisteredIds = [],
    recentStarterIds = [],
  } = params;

  const cat = filter.category && filter.category !== "전체" ? filter.category : null;

  let regCandidates = registeredMenus.filter((item) => {
    if (!(item.approval_status === "approved" && item.display_status === "approved")) return false;
    if (!item.is_available) return false;
    const r = item.restaurants;
    if (!r || r.lat == null || r.lng == null) return false;

    const dist = calculateKm(userLat, userLng, r.lat, r.lng);
    if (dist > filter.distanceKm) return false;
    if (item.price > filter.maxPrice) return false;
    if (cat && item.category !== cat) return false;
    if (filter.soloFriendly && !item.is_solo_friendly) return false;
    if (filter.takeoutAvailable && !item.is_takeout_available) return false;
    if (filter.deliveryAvailable && !item.is_delivery_available) return false;
    if (filter.veganOption && !item.is_vegan_option) return false;
    return true;
  });

  let starterCandidates = starterMenus.filter((m) => {
    if (m.display_status !== "approved") return false;
    const minP = m.expected_min_price ?? 0;
    if (minP > filter.maxPrice) return false;
    if (cat && m.category !== cat) return false;
    if (filter.soloFriendly && !m.is_solo_friendly) return false;
    if (filter.takeoutAvailable && !m.is_takeout_friendly) return false;
    if (filter.deliveryAvailable && !m.is_delivery_friendly) return false;
    if (filter.veganOption && !m.is_vegan_option) return false;
    return true;
  });

  if (filter.excludeRecent) {
    if (recentRegisteredIds.length > 0) {
      const f = regCandidates.filter((i) => !recentRegisteredIds.includes(i.id));
      if (f.length > 0) regCandidates = f;
    }
    if (recentStarterIds.length > 0) {
      const f = starterCandidates.filter((m) => !recentStarterIds.includes(m.id));
      if (f.length > 0) starterCandidates = f;
    }
  }

  const results: RecommendationResult[] = [
    ...regCandidates.map((i) => ({
      type: "registered" as const,
      menuItem: i,
      distanceKm: i.restaurants ? calculateKm(userLat, userLng, i.restaurants.lat!, i.restaurants.lng!) : undefined,
    })),
    ...starterCandidates.map((m) => ({ type: "starter" as const, starterMenu: m })),
  ];

  if (results.length === 0) return null;
  return results[Math.floor(Math.random() * results.length)];
}
