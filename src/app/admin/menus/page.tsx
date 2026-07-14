import type { Metadata } from "next";
import { requireAdmin } from "@/lib/requireAdmin";
import { AdminMenuRow } from "@/components/AdminMenuRow";

export const metadata: Metadata = { title: "메뉴 승인" };

export default async function AdminMenusPage() {
  const { supabase } = await requireAdmin();
  const { data } = await supabase
    .from("menu_items")
    .select("*, restaurants(name)")
    .eq("approval_status", "pending")
    .order("created_at", { ascending: false });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const menus = (data as any[]) ?? [];

  return (
    <div className="mx-auto max-w-4xl px-4 py-10 sm:px-6">
      <h1 className="text-2xl font-black text-dark-ink sm:text-3xl">메뉴 승인</h1>
      <div className="mt-6 space-y-3">
        {menus.length === 0 && <p className="text-sm text-text-gray">대기 중인 메뉴가 없습니다.</p>}
        {menus.map((m) => (
          <AdminMenuRow key={m.id} menu={m} restaurantName={m.restaurants?.name ?? "알 수 없음"} />
        ))}
      </div>
    </div>
  );
}
