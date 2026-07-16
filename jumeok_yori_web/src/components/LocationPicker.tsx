"use client";

import { useState } from "react";
import type { LocationState } from "@/hooks/useLocation";

export function LocationPicker({
  location,
  requesting,
  permissionError,
  onRequestBrowserLocation,
  onManualLocation,
}: {
  location: LocationState;
  requesting: boolean;
  permissionError: string | null;
  onRequestBrowserLocation: () => void;
  onManualLocation: (lat: number, lng: number, label: string, persist: boolean) => void;
}) {
  const [searchOpen, setSearchOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [searching, setSearching] = useState(false);
  const [searchError, setSearchError] = useState<string | null>(null);

  async function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    if (!query.trim()) return;
    setSearching(true);
    setSearchError(null);
    try {
      const res = await fetch(`/api/geocode?query=${encodeURIComponent(query.trim())}`);
      const json = await res.json();
      if (!json.success) {
        setSearchError(json.error ?? "주소를 찾을 수 없어요.");
        setSearching(false);
        return;
      }
      onManualLocation(json.lat, json.lng, json.roadAddress ?? query.trim(), true);
      setSearchOpen(false);
      setQuery("");
    } catch {
      setSearchError("검색 중 오류가 발생했습니다.");
    } finally {
      setSearching(false);
    }
  }

  return (
    <div className="rounded-2xl border border-soft-gray bg-white p-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-xs font-semibold text-mid-gray">기준 위치</p>
          <p className="mt-1 flex items-center gap-1.5 text-base font-bold text-dark-ink">
            <span>{location.isDefault ? "📍" : "🎯"}</span>
            {location.label}
          </p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={onRequestBrowserLocation}
            disabled={requesting}
            className="rounded-full border border-orange px-4 py-2 text-xs font-bold text-orange transition hover:bg-orange-light disabled:opacity-50"
          >
            {requesting ? "위치 확인 중..." : "내 위치 사용"}
          </button>
          <button
            onClick={() => setSearchOpen((v) => !v)}
            className="rounded-full border border-soft-gray px-4 py-2 text-xs font-bold text-dark-ink transition hover:border-orange"
          >
            직접 선택
          </button>
        </div>
      </div>

      <p className="mt-2 text-xs leading-relaxed text-mid-gray">
        위치 정보는 주변 메뉴와의 거리를 계산하는 용도로만 사용되며, 브라우저 권한을 거부해도 기준 위치를 직접
        선택해 이용할 수 있습니다.
      </p>

      {permissionError && <p className="mt-2 text-xs font-medium text-error">{permissionError}</p>}

      {searchOpen && (
        <form onSubmit={handleSearch} className="mt-3 flex gap-2">
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="예: 서울 강남구 강남대로 396"
            className="flex-1 rounded-xl border border-soft-gray px-3 py-2 text-sm outline-none focus:border-orange"
          />
          <button
            type="submit"
            disabled={searching}
            className="rounded-xl bg-orange px-4 py-2 text-sm font-bold text-white disabled:opacity-50"
          >
            {searching ? "검색 중..." : "검색"}
          </button>
        </form>
      )}
      {searchError && <p className="mt-2 text-xs font-medium text-error">{searchError}</p>}
    </div>
  );
}
