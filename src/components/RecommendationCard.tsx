"use client";

import Image from "next/image";
import Link from "next/link";
import {
  type RecommendationResult,
  menuName,
  menuCategory,
  menuImage,
  priceText,
  conditionTags,
} from "@/lib/recommend";
import { formatDistance } from "@/lib/distance";

export function RecommendationCard({
  result,
  saved,
  onToggleSave,
  onRedraw,
}: {
  result: RecommendationResult;
  saved: boolean;
  onToggleSave: () => void;
  onRedraw: () => void;
}) {
  const restaurant = result.menuItem?.restaurants;
  const image = menuImage(result);

  return (
    <div className="overflow-hidden rounded-3xl border border-soft-gray bg-white shadow-sm">
      <div className="relative h-52 w-full bg-orange-light sm:h-64">
        {image ? (
          <Image src={image} alt={menuName(result)} fill className="object-cover" />
        ) : (
          <div className="flex h-full items-center justify-center text-6xl">🍽️</div>
        )}
        <span className="absolute left-4 top-4 rounded-full bg-white/90 px-3 py-1 text-xs font-bold text-orange">
          {result.type === "registered" ? "등록 메뉴" : "기본 추천"}
        </span>
        <button
          onClick={onToggleSave}
          className="absolute right-4 top-4 flex h-10 w-10 items-center justify-center rounded-full bg-white/90 text-lg"
          aria-label="저장"
        >
          {saved ? "❤️" : "🤍"}
        </button>
      </div>

      <div className="p-6">
        <p className="text-xs font-bold text-orange">{menuCategory(result)}</p>
        <h2 className="mt-1 text-2xl font-black text-dark-ink">{menuName(result)}</h2>
        <p className="mt-2 text-lg font-bold text-dark-ink">{priceText(result)}</p>

        {result.menuItem?.description && (
          <p className="mt-3 text-sm leading-relaxed text-text-gray">{result.menuItem.description}</p>
        )}
        {result.starterMenu?.description && (
          <p className="mt-3 text-sm leading-relaxed text-text-gray">{result.starterMenu.description}</p>
        )}

        {conditionTags(result).length > 0 && (
          <div className="mt-4 flex flex-wrap gap-2">
            {conditionTags(result).map((t) => (
              <span key={t} className="rounded-full bg-orange-light px-3 py-1 text-xs font-semibold text-orange">
                {t}
              </span>
            ))}
          </div>
        )}

        {restaurant && (
          <div className="mt-5 rounded-2xl bg-ivory p-4">
            <p className="text-sm font-bold text-dark-ink">{restaurant.name}</p>
            <p className="mt-1 text-xs text-text-gray">{restaurant.address}</p>
            {result.distanceKm != null && (
              <p className="mt-1 text-xs font-semibold text-orange">
                {formatDistance(result.distanceKm)} · 도보 약 {Math.round((result.distanceKm / 4) * 60)}분
              </p>
            )}
          </div>
        )}

        <div className="mt-6 flex flex-col gap-2 sm:flex-row">
          <button
            onClick={onRedraw}
            className="flex-1 rounded-xl border border-soft-gray py-3.5 text-sm font-bold text-dark-ink transition hover:border-orange hover:text-orange"
          >
            🔄 다시 뽑기
          </button>
          {restaurant ? (
            <>
              <Link
                href={`/restaurants/${restaurant.id}`}
                className="flex-1 rounded-xl border border-soft-gray py-3.5 text-center text-sm font-bold text-dark-ink transition hover:border-orange hover:text-orange"
              >
                가게 상세보기
              </Link>
              <Link
                href={`/map?focus=${restaurant.id}`}
                className="flex-1 rounded-xl bg-orange py-3.5 text-center text-sm font-bold text-white hover:opacity-90"
              >
                지도에서 보기
              </Link>
            </>
          ) : (
            <Link
              href="/map"
              className="flex-1 rounded-xl bg-orange py-3.5 text-center text-sm font-bold text-white hover:opacity-90"
            >
              주변 가게 보기
            </Link>
          )}
        </div>
      </div>
    </div>
  );
}
