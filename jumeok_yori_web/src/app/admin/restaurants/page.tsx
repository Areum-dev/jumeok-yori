import type { Metadata } from "next";
import { requireAdmin } from "@/lib/requireAdmin";
import type { Restaurant } from "@/types/database";
import { AdminRestaurantRow } from "@/components/AdminRestaurantRow";

export const metadata: Metadata = { title: "가게 관리" };

export default async function AdminRestaurantsPage() {
  const { supabase } = await requireAdmin();
  const { data } = await supabase.from("restaurants").select("*").order("created_at", { ascending: false });
  const restaurants = (data as Restaurant[]) ?? [];

  return (
    <div className="mx-auto max-w-4xl px-4 py-10 sm:px-6">
      <h1 className="text-2xl font-black text-dark-ink sm:text-3xl">등록 가게 관리</h1>
      <p className="mt-2 text-sm text-text-gray">총 {restaurants.length}개 가게</p>
      <div className="mt-6 space-y-3">
        {restaurants.map((r) => (
          <AdminRestaurantRow key={r.id} restaurant={r} />
        ))}
      </div>
    </div>
  );
}
