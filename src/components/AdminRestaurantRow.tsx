"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { Restaurant } from "@/types/database";

export function AdminRestaurantRow({ restaurant }: { restaurant: Restaurant }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const [showCoords, setShowCoords] = useState(false);
  const [lat, setLat] = useState(restaurant.lat?.toString() ?? "");
  const [lng, setLng] = useState(restaurant.lng?.toString() ?? "");
  const [geocoding, setGeocoding] = useState(false);
  const [coordError, setCoordError] = useState<string | null>(null);
  const [coordSaved, setCoordSaved] = useState(false);

  async function setDisplayStatus(status: "approved" | "suspended") {
    const verb = status === "approved" ? "노출 재개" : "비공개 처리";
    if (!confirm(`"${restaurant.name}" 가게를 ${verb}하시겠습니까?`)) return;
    setBusy(true);
    const supabase = createClient();
    await supabase.from("restaurants").update({ display_status: status }).eq("id", restaurant.id);
    setBusy(false);
    router.refresh();
  }

  async function handleGeocodeFromAddress() {
    const fullAddress = `${restaurant.address ?? ""} ${restaurant.detail_address ?? ""}`.trim();
    if (!fullAddress) {
      setCoordError("주소 정보가 없어 자동 조회할 수 없습니다.");
      return;
    }
    setGeocoding(true);
    setCoordError(null);
    try {
      const res = await fetch(`/api/geocode?query=${encodeURIComponent(fullAddress)}`);
      const json = await res.json();
      if (!json.success) {
        setCoordError(json.error ?? "주소로 좌표를 찾지 못했습니다.");
        return;
      }
      setLat(String(json.lat));
      setLng(String(json.lng));
    } catch {
      setCoordError("지오코딩 요청 중 오류가 발생했습니다.");
    } finally {
      setGeocoding(false);
    }
  }

  async function handleSaveCoords() {
    const latNum = Number(lat);
    const lngNum = Number(lng);
    if (!lat || !lng || Number.isNaN(latNum) || Number.isNaN(lngNum)) {
      setCoordError("위도/경도를 올바른 숫자로 입력해주세요.");
      return;
    }
    // 대한민국 대략 범위 밖이면 실수로 다른 좌표(예: 기본값)를 그대로 저장하는 걸 방지
    if (latNum < 33 || latNum > 39 || lngNum < 124 || lngNum > 132) {
      if (!confirm("입력한 좌표가 대한민국 범위를 벗어난 것 같습니다. 그대로 저장하시겠습니까?")) return;
    }
    setBusy(true);
    setCoordError(null);
    const supabase = createClient();
    const { error } = await supabase.from("restaurants").update({ lat: latNum, lng: lngNum }).eq("id", restaurant.id);
    setBusy(false);
    if (error) {
      setCoordError("좌표 저장 중 오류가 발생했습니다.");
      return;
    }
    setCoordSaved(true);
    router.refresh();
  }

  return (
    <div className="rounded-2xl border border-soft-gray bg-white p-5">
      <div className="flex items-center justify-between">
        <div className="min-w-0">
          <div className="flex items-center gap-2">
            <p className="truncate font-bold text-dark-ink">{restaurant.name}</p>
            <span
              className={`shrink-0 rounded-full px-2.5 py-0.5 text-[10px] font-bold ${
                restaurant.display_status === "approved" ? "bg-green-50 text-success" : "bg-soft-gray text-mid-gray"
              }`}
            >
              {restaurant.display_status === "approved" ? "노출 중" : "비공개"}
            </span>
          </div>
          <p className="mt-1 truncate text-xs text-text-gray">{restaurant.address}</p>
          <p className="mt-1 text-[11px] text-mid-gray">
            현재 좌표: {restaurant.lat != null && restaurant.lng != null ? `${restaurant.lat}, ${restaurant.lng}` : "없음"}
          </p>
        </div>
        <div className="flex shrink-0 gap-2">
          <Link
            href={`/restaurants/${restaurant.id}`}
            className="rounded-lg border border-soft-gray px-3 py-2 text-xs font-semibold text-dark-ink hover:border-orange"
          >
            보기
          </Link>
          <button
            onClick={() => setShowCoords((v) => !v)}
            className="rounded-lg border border-soft-gray px-3 py-2 text-xs font-semibold text-dark-ink hover:border-orange"
          >
            좌표 수정
          </button>
          {restaurant.display_status === "approved" ? (
            <button
              onClick={() => setDisplayStatus("suspended")}
              disabled={busy}
              className="rounded-lg border border-error/40 px-3 py-2 text-xs font-semibold text-error disabled:opacity-50"
            >
              비공개
            </button>
          ) : (
            <button
              onClick={() => setDisplayStatus("approved")}
              disabled={busy}
              className="rounded-lg bg-orange px-3 py-2 text-xs font-semibold text-white disabled:opacity-50"
            >
              노출 재개
            </button>
          )}
        </div>
      </div>

      {showCoords && (
        <div className="mt-4 rounded-xl border border-orange/40 bg-orange-light/40 p-4">
          <p className="text-xs font-bold text-dark-ink">가게 좌표 수정</p>
          <p className="mt-1 text-[11px] text-text-gray">
            주소로 자동 조회하거나(Naver Geocoding 활성화 필요), 지도에서 직접 확인한 좌표를 입력하세요.
          </p>
          <div className="mt-3 flex gap-2">
            <input
              value={lat}
              onChange={(e) => setLat(e.target.value)}
              placeholder="위도 (예: 37.4979)"
              className="w-1/2 rounded-lg border border-soft-gray px-3 py-2 text-xs outline-none focus:border-orange"
            />
            <input
              value={lng}
              onChange={(e) => setLng(e.target.value)}
              placeholder="경도 (예: 127.0276)"
              className="w-1/2 rounded-lg border border-soft-gray px-3 py-2 text-xs outline-none focus:border-orange"
            />
          </div>
          {coordError && <p className="mt-2 text-xs font-medium text-error">{coordError}</p>}
          {coordSaved && <p className="mt-2 text-xs font-medium text-success">좌표가 저장되었습니다.</p>}
          <div className="mt-3 flex gap-2">
            <button
              onClick={handleGeocodeFromAddress}
              disabled={geocoding}
              className="rounded-lg border border-soft-gray bg-white px-3 py-2 text-xs font-semibold text-dark-ink disabled:opacity-50"
            >
              {geocoding ? "조회 중..." : "주소로 좌표 자동 조회"}
            </button>
            <button
              onClick={handleSaveCoords}
              disabled={busy}
              className="rounded-lg bg-orange px-3 py-2 text-xs font-semibold text-white disabled:opacity-50"
            >
              좌표 저장
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
