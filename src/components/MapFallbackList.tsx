import Link from "next/link";
import { calculateKm, formatDistance } from "@/lib/distance";
import type { Restaurant } from "@/types/database";

/** 지도 API 를 사용할 수 없을 때 보여주는 거리순 목록 (Flutter map_fallback_store_list.dart 와 동등) */
export function MapFallbackList({
  restaurants,
  userLat,
  userLng,
}: {
  restaurants: Restaurant[];
  userLat: number;
  userLng: number;
}) {
  const sorted = [...restaurants]
    .filter((r) => r.lat != null && r.lng != null)
    .map((r) => ({ r, dist: calculateKm(userLat, userLng, r.lat!, r.lng!) }))
    .sort((a, b) => a.dist - b.dist);

  if (sorted.length === 0) {
    return (
      <div className="rounded-2xl border border-dashed border-soft-gray bg-white p-10 text-center text-text-gray">
        아직 좌표가 등록된 가게가 없어요.
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {sorted.map(({ r, dist }) => (
        <Link
          key={r.id}
          href={`/restaurants/${r.id}`}
          className="flex items-center justify-between rounded-2xl border border-soft-gray bg-white p-4 transition hover:border-orange"
        >
          <div className="min-w-0">
            <p className="truncate text-sm font-bold text-dark-ink">{r.name}</p>
            <p className="mt-1 truncate text-xs text-text-gray">{r.address}</p>
          </div>
          <span className="ml-3 shrink-0 text-sm font-bold text-orange">{formatDistance(dist)}</span>
        </Link>
      ))}
    </div>
  );
}
