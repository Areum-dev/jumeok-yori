import type { Metadata } from "next";
import Link from "next/link";
import { requireAdmin } from "@/lib/requireAdmin";

export const metadata: Metadata = { title: "관리자" };

export default async function AdminPage() {
  const { supabase } = await requireAdmin();

  const [pendingApps, pendingMenus, pendingReports, totalRestaurants, totalUsers] = await Promise.all([
    supabase.from("owner_store_applications").select("id", { count: "exact", head: true }).eq("status", "pending"),
    supabase.from("menu_items").select("id", { count: "exact", head: true }).eq("approval_status", "pending"),
    supabase.from("reports").select("id", { count: "exact", head: true }).eq("status", "pending"),
    supabase.from("restaurants").select("id", { count: "exact", head: true }),
    supabase.from("profiles").select("id", { count: "exact", head: true }),
  ]);

  const cards = [
    { label: "가게 승인 대기", value: pendingApps.count ?? 0, href: "/admin/applications" },
    { label: "메뉴 승인 대기", value: pendingMenus.count ?? 0, href: "/admin/menus" },
    { label: "미처리 신고", value: pendingReports.count ?? 0, href: "/admin/reports" },
    { label: "전체 가게", value: totalRestaurants.count ?? 0, href: "/admin/restaurants" },
    { label: "전체 회원", value: totalUsers.count ?? 0, href: "/admin/applications" },
  ];

  return (
    <div className="mx-auto max-w-4xl px-4 py-10 sm:px-6">
      <h1 className="text-2xl font-black text-dark-ink sm:text-3xl">관리자 대시보드</h1>
      <div className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-3">
        {cards.map((c) => (
          <Link
            key={c.label}
            href={c.href}
            className="rounded-2xl border border-soft-gray bg-white p-5 text-center transition hover:border-orange"
          >
            <p className="text-2xl font-black text-orange">{c.value}</p>
            <p className="mt-1 text-xs font-semibold text-dark-ink">{c.label}</p>
          </Link>
        ))}
      </div>

      <div className="mt-10 grid grid-cols-1 gap-3 sm:grid-cols-2">
        <Link href="/admin/applications" className="rounded-2xl border border-soft-gray bg-white p-5 font-bold text-dark-ink hover:border-orange">
          가게 등록 승인 관리 →
        </Link>
        <Link href="/admin/menus" className="rounded-2xl border border-soft-gray bg-white p-5 font-bold text-dark-ink hover:border-orange">
          메뉴 승인 관리 →
        </Link>
        <Link href="/admin/restaurants" className="rounded-2xl border border-soft-gray bg-white p-5 font-bold text-dark-ink hover:border-orange">
          등록 가게 전체 관리 →
        </Link>
        <Link href="/admin/reports" className="rounded-2xl border border-soft-gray bg-white p-5 font-bold text-dark-ink hover:border-orange">
          신고 처리 →
        </Link>
      </div>
    </div>
  );
}
