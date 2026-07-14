import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import type { MenuItem, Restaurant } from "@/types/database";

interface Props {
  params: Promise<{ id: string }>;
}

async function getRestaurant(id: string) {
  const supabase = await createClient();
  const { data: restaurant } = await supabase.from("restaurants").select("*").eq("id", id).maybeSingle();
  if (!restaurant) return null;

  const { data: menus } = await supabase
    .from("menu_items")
    .select("*")
    .eq("restaurant_id", id)
    .eq("approval_status", "approved")
    .eq("display_status", "approved")
    .eq("is_available", true)
    .order("created_at", { ascending: false });

  // 조회 이벤트 기록 (실패해도 무시)
  try {
    await supabase.from("analytics_events").insert({
      event_type: "restaurant_viewed",
      owner_id: (restaurant as Restaurant).owner_id,
      restaurant_id: id,
    });
  } catch {
    // no-op
  }

  return { restaurant: restaurant as Restaurant, menus: (menus as MenuItem[]) ?? [] };
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const data = await getRestaurant(id);
  return { title: data?.restaurant.name ?? "음식점 정보" };
}

export default async function RestaurantDetailPage({ params }: Props) {
  const { id } = await params;
  const data = await getRestaurant(id);

  if (!data || data.restaurant.display_status !== "approved") {
    notFound();
  }

  const { restaurant, menus } = data;
  const directionsUrl = `https://map.naver.com/p/search/${encodeURIComponent(
    restaurant.address ?? restaurant.name,
  )}`;

  return (
    <div className="mx-auto max-w-3xl px-4 py-10 sm:px-6">
      <div className="overflow-hidden rounded-3xl border border-soft-gray bg-white">
        <div className="relative h-56 w-full bg-orange-light sm:h-72">
          {restaurant.image_url ? (
            <Image src={restaurant.image_url} alt={restaurant.name} fill className="object-cover" />
          ) : (
            <div className="flex h-full items-center justify-center text-6xl">🏪</div>
          )}
        </div>
        <div className="p-6 sm:p-8">
          <p className="text-xs font-bold text-orange">{restaurant.category ?? "기타"}</p>
          <h1 className="mt-1 text-2xl font-black text-dark-ink sm:text-3xl">{restaurant.name}</h1>

          <div className="mt-4 space-y-1.5 text-sm text-text-gray">
            <p>📍 {restaurant.address} {restaurant.detail_address}</p>
            {restaurant.phone && <p>📞 {restaurant.phone}</p>}
            {restaurant.opening_hours && <p>🕐 {restaurant.opening_hours}</p>}
          </div>

          {restaurant.description && (
            <p className="mt-4 text-sm leading-relaxed text-dark-ink">{restaurant.description}</p>
          )}

          <div className="mt-4 flex flex-wrap gap-2">
            {restaurant.is_takeout_available && (
              <span className="rounded-full bg-orange-light px-3 py-1 text-xs font-semibold text-orange">
                포장 가능
              </span>
            )}
            {restaurant.is_delivery_available && (
              <span className="rounded-full bg-orange-light px-3 py-1 text-xs font-semibold text-orange">
                배달 가능
              </span>
            )}
          </div>

          <div className="mt-6 flex flex-col gap-2 sm:flex-row">
            <a
              href={directionsUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="flex-1 rounded-xl bg-orange py-3.5 text-center text-sm font-bold text-white hover:opacity-90"
            >
              🧭 길찾기 (네이버 지도)
            </a>
            {restaurant.lat != null && restaurant.lng != null && (
              <Link
                href={`/map?focus=${restaurant.id}`}
                className="flex-1 rounded-xl border border-soft-gray py-3.5 text-center text-sm font-bold text-dark-ink transition hover:border-orange hover:text-orange"
              >
                주먹지도에서 보기
              </Link>
            )}
          </div>
        </div>
      </div>

      <div className="mt-10">
        <h2 className="text-xl font-extrabold text-dark-ink">메뉴</h2>
        {menus.length === 0 ? (
          <p className="mt-4 text-sm text-text-gray">아직 등록된 메뉴가 없어요.</p>
        ) : (
          <div className="mt-5 grid grid-cols-1 gap-4 sm:grid-cols-2">
            {menus.map((m) => (
              <div key={m.id} className="flex gap-4 rounded-2xl border border-soft-gray bg-white p-4">
                <div className="relative h-20 w-20 shrink-0 overflow-hidden rounded-xl bg-orange-light">
                  {m.image_url ? (
                    <Image src={m.image_url} alt={m.name} fill className="object-cover" />
                  ) : (
                    <div className="flex h-full items-center justify-center text-2xl">🍚</div>
                  )}
                </div>
                <div className="min-w-0">
                  <p className="truncate text-sm font-bold text-dark-ink">{m.name}</p>
                  <p className="mt-1 text-sm font-semibold text-orange">{m.price.toLocaleString("ko-KR")}원</p>
                  {m.description && <p className="mt-1 line-clamp-2 text-xs text-text-gray">{m.description}</p>}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
