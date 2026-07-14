import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import type { Restaurant, OwnerStoreApplication } from "@/types/database";

export const metadata: Metadata = { title: "사장님" };

const STATUS_LABEL: Record<string, string> = {
  pending: "검수 대기",
  approved: "승인됨",
  rejected: "반려됨",
  suspended: "정지됨",
};

export default async function OwnerPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login?error=" + encodeURIComponent("사장님 기능은 로그인이 필요합니다."));

  const [{ data: restaurants }, { data: applications }] = await Promise.all([
    supabase.from("restaurants").select("*").eq("owner_id", user.id).order("created_at", { ascending: false }),
    supabase
      .from("owner_store_applications")
      .select("*")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false }),
  ]);

  const stores = (restaurants as Restaurant[]) ?? [];
  const apps = (applications as OwnerStoreApplication[]) ?? [];
  const pendingApps = apps.filter((a) => !a.restaurant_id);

  return (
    <div className="mx-auto max-w-4xl px-4 py-10 sm:px-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-black text-dark-ink sm:text-3xl">내 가게</h1>
        <Link
          href="/owner/apply"
          className="rounded-full bg-orange px-5 py-2.5 text-sm font-bold text-white hover:opacity-90"
        >
          + 새 가게 등록
        </Link>
      </div>

      {stores.length === 0 && pendingApps.length === 0 && (
        <div className="mt-8 rounded-2xl border border-dashed border-soft-gray bg-white p-12 text-center">
          <p className="text-base font-bold text-dark-ink">아직 등록된 가게가 없어요.</p>
          <p className="mt-2 text-sm text-text-gray">가게를 등록하고 주먹요리 추천에 노출시켜보세요.</p>
          <Link
            href="/owner/apply"
            className="mt-5 inline-block rounded-full bg-orange px-6 py-3 text-sm font-bold text-white hover:opacity-90"
          >
            가게 등록하기
          </Link>
        </div>
      )}

      {pendingApps.length > 0 && (
        <div className="mt-8">
          <h2 className="text-sm font-bold text-mid-gray">검수 중인 신청</h2>
          <div className="mt-3 space-y-3">
            {pendingApps.map((a) => (
              <div key={a.id} className="rounded-2xl border border-soft-gray bg-white p-5">
                <div className="flex items-center justify-between">
                  <p className="font-bold text-dark-ink">{a.store_name}</p>
                  <span
                    className={`rounded-full px-3 py-1 text-xs font-bold ${
                      a.status === "rejected" ? "bg-red-50 text-error" : "bg-orange-light text-orange"
                    }`}
                  >
                    {STATUS_LABEL[a.status] ?? a.status}
                  </span>
                </div>
                <p className="mt-1 text-xs text-text-gray">{a.address}</p>
                {a.status === "rejected" && a.admin_note && (
                  <p className="mt-2 text-xs text-error">반려 사유: {a.admin_note}</p>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {stores.length > 0 && (
        <div className="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-2">
          {stores.map((r) => (
            <Link
              key={r.id}
              href={`/owner/${r.id}`}
              className="rounded-2xl border border-soft-gray bg-white p-5 transition hover:border-orange"
            >
              <div className="flex items-center justify-between">
                <p className="font-bold text-dark-ink">{r.name}</p>
                <span
                  className={`rounded-full px-3 py-1 text-xs font-bold ${
                    r.display_status === "approved" ? "bg-green-50 text-success" : "bg-soft-gray text-mid-gray"
                  }`}
                >
                  {r.display_status === "approved" ? "노출 중" : STATUS_LABEL[r.verification_status] ?? r.verification_status}
                </span>
              </div>
              <p className="mt-2 text-xs text-text-gray">{r.address}</p>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
