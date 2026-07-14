import type { Metadata } from "next";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import type { Restaurant } from "@/types/database";

export const metadata: Metadata = { title: "음식점" };

async function getRestaurants(): Promise<Restaurant[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("restaurants")
    .select("*")
    .eq("display_status", "approved")
    .order("created_at", { ascending: false });
  return (data as Restaurant[]) ?? [];
}

export default async function RestaurantsPage() {
  const restaurants = await getRestaurants();

  return (
    <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
      <h1 className="text-2xl font-black text-dark-ink sm:text-3xl">등록된 음식점</h1>
      <p className="mt-2 text-sm text-text-gray">관리자 승인을 마친 음식점만 노출됩니다.</p>

      {restaurants.length === 0 ? (
        <div className="mt-10 rounded-2xl border border-dashed border-soft-gray bg-white p-12 text-center">
          <p className="text-base font-bold text-dark-ink">아직 등록된 가게가 없어요.</p>
          <p className="mt-2 text-sm text-text-gray">기본 추천 메뉴로 오늘의 메뉴를 먼저 뽑아보세요.</p>
          <Link
            href="/recommend"
            className="mt-5 inline-block rounded-full bg-orange px-6 py-3 text-sm font-bold text-white hover:opacity-90"
          >
            메뉴 뽑으러 가기
          </Link>
        </div>
      ) : (
        <div className="mt-8 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {restaurants.map((r) => (
            <Link
              key={r.id}
              href={`/restaurants/${r.id}`}
              className="rounded-2xl border border-soft-gray bg-white p-5 transition hover:border-orange"
            >
              <p className="text-xs font-bold text-orange">{r.category ?? "기타"}</p>
              <h2 className="mt-1 text-lg font-bold text-dark-ink">{r.name}</h2>
              <p className="mt-2 line-clamp-2 text-sm text-text-gray">{r.address}</p>
              <div className="mt-3 flex gap-2 text-xs text-mid-gray">
                {r.is_takeout_available && <span className="rounded-full bg-ivory px-2 py-1">포장 가능</span>}
                {r.is_delivery_available && <span className="rounded-full bg-ivory px-2 py-1">배달 가능</span>}
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
