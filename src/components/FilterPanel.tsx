"use client";

import { AppConfig } from "@/lib/config";
import type { RecommendationFilter } from "@/lib/recommend";

const TOGGLES: { key: keyof RecommendationFilter; label: string }[] = [
  { key: "soloFriendly", label: "혼밥 OK" },
  { key: "takeoutAvailable", label: "포장 가능" },
  { key: "deliveryAvailable", label: "배달 가능" },
  { key: "veganOption", label: "비건 옵션" },
];

export function FilterPanel({
  filter,
  onChange,
}: {
  filter: RecommendationFilter;
  onChange: (next: RecommendationFilter) => void;
}) {
  return (
    <div className="space-y-6 rounded-2xl border border-soft-gray bg-white p-5">
      <div>
        <div className="mb-2 flex items-center justify-between">
          <label className="text-sm font-bold text-dark-ink">거리</label>
          <span className="text-sm font-bold text-orange">
            {filter.distanceKm < 1 ? `${Math.round(filter.distanceKm * 1000)}m` : `${filter.distanceKm}km`} 이내
          </span>
        </div>
        <input
          type="range"
          min={0.5}
          max={5}
          step={0.5}
          value={filter.distanceKm}
          onChange={(e) => onChange({ ...filter, distanceKm: Number(e.target.value) })}
          className="w-full accent-orange"
        />
      </div>

      <div>
        <div className="mb-2 flex items-center justify-between">
          <label className="text-sm font-bold text-dark-ink">가격</label>
          <span className="text-sm font-bold text-orange">{filter.maxPrice.toLocaleString("ko-KR")}원 이하</span>
        </div>
        <input
          type="range"
          min={5000}
          max={30000}
          step={1000}
          value={filter.maxPrice}
          onChange={(e) => onChange({ ...filter, maxPrice: Number(e.target.value) })}
          className="w-full accent-orange"
        />
      </div>

      <div>
        <label className="mb-2 block text-sm font-bold text-dark-ink">음식 종류</label>
        <div className="flex flex-wrap gap-2">
          {AppConfig.categoryOptions.map((c) => {
            const active = (filter.category ?? "전체") === c;
            return (
              <button
                key={c}
                onClick={() => onChange({ ...filter, category: c === "전체" ? null : c })}
                className={`rounded-full border px-4 py-2 text-xs font-semibold transition ${
                  active
                    ? "border-orange bg-orange text-white"
                    : "border-soft-gray bg-ivory text-dark-ink hover:border-orange"
                }`}
              >
                {c}
              </button>
            );
          })}
        </div>
      </div>

      <div>
        <label className="mb-2 block text-sm font-bold text-dark-ink">조건</label>
        <div className="flex flex-wrap gap-2">
          {TOGGLES.map((t) => {
            const active = Boolean(filter[t.key]);
            return (
              <button
                key={t.key}
                onClick={() => onChange({ ...filter, [t.key]: !active })}
                className={`rounded-full border px-4 py-2 text-xs font-semibold transition ${
                  active
                    ? "border-orange bg-orange text-white"
                    : "border-soft-gray bg-ivory text-dark-ink hover:border-orange"
                }`}
              >
                {t.label}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
