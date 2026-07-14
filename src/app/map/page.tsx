"use client";

import { useEffect, useRef, useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { useLocation } from "@/hooks/useLocation";
import { LocationPicker } from "@/components/LocationPicker";
import { MapFallbackList } from "@/components/MapFallbackList";
import { calculateKm, formatDistance } from "@/lib/distance";
import type { Restaurant } from "@/types/database";

declare global {
  interface Window {
    naver: any; // eslint-disable-line @typescript-eslint/no-explicit-any
  }
}

const SCRIPT_ID = "naver-maps-sdk";
const LOAD_TIMEOUT_MS = 6000;

function loadNaverMapsScript(clientId: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if (window.naver?.maps) {
      resolve();
      return;
    }
    const existing = document.getElementById(SCRIPT_ID);
    if (existing) {
      existing.addEventListener("load", () => resolve());
      existing.addEventListener("error", () => reject(new Error("script load error")));
      return;
    }
    const script = document.createElement("script");
    script.id = SCRIPT_ID;
    script.src = `https://oapi.map.naver.com/openapi/v3/maps.js?ncpKeyId=${clientId}`;
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error("script load error"));
    document.head.appendChild(script);

    const timer = setTimeout(() => reject(new Error("timeout")), LOAD_TIMEOUT_MS);
    script.addEventListener("load", () => clearTimeout(timer));
  });
}

function MapPageInner() {
  const searchParams = useSearchParams();
  const focusId = searchParams.get("focus");

  const { location, requesting, permissionError, requestBrowserLocation, setManualLocation } = useLocation();
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [loading, setLoading] = useState(true);
  const [mapReady, setMapReady] = useState(false);
  const [mapError, setMapError] = useState<string | null>(null);
  const [selected, setSelected] = useState<Restaurant | null>(null);

  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapInstanceRef = useRef<any>(null); // eslint-disable-line @typescript-eslint/no-explicit-any
  const markersRef = useRef<any[]>([]); // eslint-disable-line @typescript-eslint/no-explicit-any

  // 가게 목록 로드
  useEffect(() => {
    let mounted = true;
    (async () => {
      setLoading(true);
      const supabase = createClient();
      const { data } = await supabase.from("restaurants").select("*").eq("display_status", "approved");
      if (!mounted) return;
      setRestaurants((data as Restaurant[]) ?? []);
      setLoading(false);
    })();
    return () => {
      mounted = false;
    };
  }, []);

  // 지도 SDK 로드
  useEffect(() => {
    const clientId = process.env.NEXT_PUBLIC_NAVER_MAP_CLIENT_ID;
    if (!clientId) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setMapError("지도 API 키가 설정되지 않았습니다.");
      return;
    }
    (window as unknown as { navermap_authFailure?: () => void }).navermap_authFailure = () => {
      setMapError("지도 인증에 실패했습니다. 목록으로 안내해드릴게요.");
    };
    loadNaverMapsScript(clientId)
      .then(() => setMapReady(true))
      .catch(() => setMapError("지도를 불러오지 못했습니다. 목록으로 안내해드릴게요."));
  }, []);

  // 지도 초기화 + 마커 렌더링
  useEffect(() => {
    if (!mapReady || !mapContainerRef.current || mapError) return;
    const { naver } = window;
    if (!mapInstanceRef.current) {
      mapInstanceRef.current = new naver.maps.Map(mapContainerRef.current, {
        center: new naver.maps.LatLng(location.lat, location.lng),
        zoom: 14,
      });
    }

    markersRef.current.forEach((m) => m.setMap(null));
    markersRef.current = [];

    const withCoords = restaurants.filter((r) => r.lat != null && r.lng != null);
    withCoords.forEach((r) => {
      const marker = new naver.maps.Marker({
        position: new naver.maps.LatLng(r.lat!, r.lng!),
        map: mapInstanceRef.current,
        title: r.name,
      });
      naver.maps.Event.addListener(marker, "click", () => setSelected(r));
      markersRef.current.push(marker);
    });

    if (focusId) {
      const target = withCoords.find((r) => r.id === focusId);
      if (target) {
        mapInstanceRef.current.setCenter(new naver.maps.LatLng(target.lat!, target.lng!));
        mapInstanceRef.current.setZoom(16);
        // eslint-disable-next-line react-hooks/set-state-in-effect
        setSelected(target);
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mapReady, restaurants, mapError, focusId]);

  const showFallback = Boolean(mapError);

  return (
    <div className="mx-auto max-w-6xl px-4 py-8 sm:px-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-2xl font-black text-dark-ink sm:text-3xl">주먹지도</h1>
        <p className="text-sm text-text-gray">승인된 가게를 지도에서 확인해보세요.</p>
      </div>

      <div className="mt-4">
        <LocationPicker
          location={location}
          requesting={requesting}
          permissionError={permissionError}
          onRequestBrowserLocation={requestBrowserLocation}
          onManualLocation={setManualLocation}
        />
      </div>

      <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-[1fr_320px]">
        <div className="relative h-[480px] overflow-hidden rounded-2xl border border-soft-gray bg-white">
          {loading ? (
            <div className="flex h-full items-center justify-center text-sm text-text-gray">
              가게 정보를 불러오는 중...
            </div>
          ) : showFallback ? (
            <div className="h-full overflow-y-auto p-4">
              <p className="mb-3 text-xs font-medium text-mid-gray">{mapError}</p>
              <MapFallbackList restaurants={restaurants} userLat={location.lat} userLng={location.lng} />
            </div>
          ) : (
            <div ref={mapContainerRef} className="h-full w-full" />
          )}
          {!loading && !showFallback && !mapReady && (
            <div className="absolute inset-0 flex items-center justify-center bg-white/80 text-sm text-text-gray">
              지도를 불러오는 중...
            </div>
          )}
        </div>

        <div className="space-y-3">
          {selected ? (
            <div className="rounded-2xl border border-orange bg-white p-5">
              <p className="text-xs font-bold text-orange">{selected.category ?? "기타"}</p>
              <h2 className="mt-1 text-lg font-bold text-dark-ink">{selected.name}</h2>
              <p className="mt-2 text-xs text-text-gray">{selected.address}</p>
              {selected.lat != null && selected.lng != null && (
                <p className="mt-2 text-xs font-semibold text-orange">
                  {formatDistance(calculateKm(location.lat, location.lng, selected.lat, selected.lng))}
                </p>
              )}
              <Link
                href={`/restaurants/${selected.id}`}
                className="mt-4 block rounded-xl bg-orange py-3 text-center text-sm font-bold text-white hover:opacity-90"
              >
                상세보기
              </Link>
            </div>
          ) : (
            <div className="rounded-2xl border border-dashed border-soft-gray bg-white p-6 text-center text-sm text-text-gray">
              지도의 핀을 눌러 가게 정보를 확인하세요.
            </div>
          )}

          <Link
            href="/owner"
            className="block rounded-2xl border border-soft-gray bg-white p-5 text-center text-sm font-bold text-dark-ink transition hover:border-orange hover:text-orange"
          >
            내 가게가 지도에 없나요? 등록하기 →
          </Link>
        </div>
      </div>
    </div>
  );
}

export default function MapPage() {
  return (
    <Suspense>
      <MapPageInner />
    </Suspense>
  );
}
