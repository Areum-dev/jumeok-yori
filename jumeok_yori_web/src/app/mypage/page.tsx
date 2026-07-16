import type { Metadata } from "next";
import Link from "next/link";
import Image from "next/image";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import type { Profile } from "@/types/database";
import { SignOutButton } from "@/components/SignOutButton";

export const metadata: Metadata = { title: "마이페이지" };

const ROLE_LABEL: Record<string, string> = { user: "일반 회원", owner: "사장님", admin: "관리자" };

export default async function MyPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const { data: profile } = await supabase.from("profiles").select("*").eq("id", user.id).maybeSingle();
  const p = profile as Profile | null;

  const { data: hasApplication } = await supabase
    .from("owner_store_applications")
    .select("id")
    .eq("user_id", user.id)
    .limit(1);

  const { data: history } = await supabase
    .from("recommendation_logs")
    .select(
      "id, created_at, recommendation_type, menu_items(name, price, image_url, restaurants(name)), starter_menus(name, image_url, expected_min_price, expected_max_price)",
    )
    .eq("user_id", user.id)
    .order("created_at", { ascending: false })
    .limit(15);

  const { data: saved } = await supabase
    .from("saved_menu_items")
    .select(
      "id, created_at, recommendation_type, menu_items(id, name, price, image_url, restaurants(name)), starter_menus(id, name, image_url, expected_min_price, expected_max_price)",
    )
    .eq("user_id", user.id)
    .order("created_at", { ascending: false });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const historyRows = (history as any[]) ?? [];
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const savedRows = (saved as any[]) ?? [];

  return (
    <div className="mx-auto max-w-3xl px-4 py-10 sm:px-6">
      <div className="rounded-2xl border border-soft-gray bg-white p-6">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-lg font-bold text-dark-ink">{p?.display_name || user.email}</p>
            <p className="mt-1 text-sm text-text-gray">{user.email}</p>
            <span className="mt-2 inline-block rounded-full bg-orange-light px-3 py-1 text-xs font-bold text-orange">
              {ROLE_LABEL[p?.role ?? "user"] ?? p?.role}
            </span>
          </div>
          <Link
            href="/mypage/edit"
            className="rounded-full border border-soft-gray px-4 py-2 text-xs font-bold text-dark-ink hover:border-orange hover:text-orange"
          >
            프로필 수정
          </Link>
        </div>
      </div>

      <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-3">
        <Link
          href="/owner"
          className="rounded-2xl border border-soft-gray bg-white p-4 text-center text-sm font-bold text-dark-ink hover:border-orange hover:text-orange"
        >
          {p?.role === "owner" || p?.role === "admin"
            ? "내 가게 관리"
            : hasApplication && hasApplication.length > 0
              ? "가게 신청 현황"
              : "사장님 가게 등록"}
        </Link>
        {p?.role === "admin" && (
          <Link
            href="/admin"
            className="rounded-2xl border border-soft-gray bg-white p-4 text-center text-sm font-bold text-dark-ink hover:border-orange hover:text-orange"
          >
            관리자 페이지
          </Link>
        )}
        <Link
          href="/support"
          className="rounded-2xl border border-soft-gray bg-white p-4 text-center text-sm font-bold text-dark-ink hover:border-orange hover:text-orange"
        >
          고객지원
        </Link>
        <Link
          href="/delete-account"
          className="rounded-2xl border border-soft-gray bg-white p-4 text-center text-sm font-bold text-error hover:border-error"
        >
          계정 삭제
        </Link>
      </div>

      <div className="mt-4">
        <SignOutButton />
      </div>

      <section className="mt-10">
        <h2 className="text-lg font-extrabold text-dark-ink">저장한 메뉴</h2>
        {savedRows.length === 0 ? (
          <p className="mt-3 text-sm text-text-gray">아직 저장한 메뉴가 없어요.</p>
        ) : (
          <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2">
            {savedRows.map((row) => {
              const m = row.menu_items;
              const s = row.starter_menus;
              const name = m?.name ?? s?.name;
              const image = m?.image_url ?? s?.image_url;
              return (
                <div key={row.id} className="flex gap-3 rounded-2xl border border-soft-gray bg-white p-4">
                  <div className="relative h-16 w-16 shrink-0 overflow-hidden rounded-xl bg-orange-light">
                    {image ? (
                      <Image src={image} alt={name} fill className="object-cover" />
                    ) : (
                      <div className="flex h-full items-center justify-center text-xl">🍽️</div>
                    )}
                  </div>
                  <div className="min-w-0">
                    <p className="truncate text-sm font-bold text-dark-ink">{name}</p>
                    {m?.restaurants?.name && <p className="truncate text-xs text-text-gray">{m.restaurants.name}</p>}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </section>

      <section className="mt-10">
        <h2 className="text-lg font-extrabold text-dark-ink">추천 기록</h2>
        {historyRows.length === 0 ? (
          <p className="mt-3 text-sm text-text-gray">아직 추천받은 메뉴가 없어요.</p>
        ) : (
          <ul className="mt-4 divide-y divide-soft-gray rounded-2xl border border-soft-gray bg-white">
            {historyRows.map((row) => {
              const m = row.menu_items;
              const s = row.starter_menus;
              const name = m?.name ?? s?.name;
              return (
                <li key={row.id} className="flex items-center justify-between p-4">
                  <div>
                    <p className="text-sm font-bold text-dark-ink">{name}</p>
                    {m?.restaurants?.name && <p className="text-xs text-text-gray">{m.restaurants.name}</p>}
                  </div>
                  <span className="text-xs text-mid-gray">
                    {new Date(row.created_at).toLocaleDateString("ko-KR")}
                  </span>
                </li>
              );
            })}
          </ul>
        )}
      </section>
    </div>
  );
}
