"use client";

import type { RecommendationFilter } from "@/lib/recommend";
import { defaultFilter } from "@/lib/recommend";

/**
 * 브라우저 localStorage 기반 로컬 상태 저장.
 * jumeok_yori(Flutter) local_user_service.dart / filter_storage_service.dart 와 동등한 역할.
 */

const KEYS = {
  anonymousId: "jumeok_anonymous_user_id",
  recentRegistered: "jumeok_recent_registered_ids",
  recentStarter: "jumeok_recent_starter_ids",
  filter: "jumeok_filter",
};

function readList(key: string): string[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = window.localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as string[]) : [];
  } catch {
    return [];
  }
}

function writeList(key: string, list: string[]) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(key, JSON.stringify(list));
}

function pushRecent(key: string, id: string, max = 5) {
  const list = readList(key).filter((x) => x !== id);
  list.unshift(id);
  writeList(key, list.slice(0, max));
}

export function getOrCreateAnonymousId(): string {
  if (typeof window === "undefined") return "";
  let id = window.localStorage.getItem(KEYS.anonymousId);
  if (!id) {
    id = crypto.randomUUID();
    window.localStorage.setItem(KEYS.anonymousId, id);
  }
  return id;
}

export const getRecentRegisteredIds = () => readList(KEYS.recentRegistered);
export const addRecentRegisteredId = (id: string) => pushRecent(KEYS.recentRegistered, id);
export const getRecentStarterIds = () => readList(KEYS.recentStarter);
export const addRecentStarterId = (id: string) => pushRecent(KEYS.recentStarter, id);

export function loadFilter(): RecommendationFilter {
  if (typeof window === "undefined") return defaultFilter;
  try {
    const raw = window.localStorage.getItem(KEYS.filter);
    if (!raw) return defaultFilter;
    return { ...defaultFilter, ...(JSON.parse(raw) as Partial<RecommendationFilter>) };
  } catch {
    return defaultFilter;
  }
}

export function saveFilter(filter: RecommendationFilter) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(KEYS.filter, JSON.stringify(filter));
}

/** 사용자가 직접 지정한 기준 위치 (일시 사용과 구분되는 저장 위치) */
export function getSavedLocation(): { lat: number; lng: number; label: string } | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem("jumeok_saved_location");
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function saveLocation(lat: number, lng: number, label: string) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem("jumeok_saved_location", JSON.stringify({ lat, lng, label }));
}

export function clearSavedLocation() {
  if (typeof window === "undefined") return;
  window.localStorage.removeItem("jumeok_saved_location");
}
