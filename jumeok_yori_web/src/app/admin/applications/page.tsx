import type { Metadata } from "next";
import { requireAdmin } from "@/lib/requireAdmin";
import type { OwnerStoreApplication } from "@/types/database";
import { AdminApplicationRow } from "@/components/AdminApplicationRow";

export const metadata: Metadata = { title: "가게 등록 승인" };

export default async function AdminApplicationsPage() {
  const { supabase } = await requireAdmin();
  const { data } = await supabase
    .from("owner_store_applications")
    .select("*")
    .order("created_at", { ascending: false });

  const apps = (data as OwnerStoreApplication[]) ?? [];
  const pending = apps.filter((a) => a.status === "pending");
  const others = apps.filter((a) => a.status !== "pending");

  return (
    <div className="mx-auto max-w-4xl px-4 py-10 sm:px-6">
      <h1 className="text-2xl font-black text-dark-ink sm:text-3xl">가게 등록 승인</h1>

      <section className="mt-6">
        <h2 className="text-sm font-bold text-mid-gray">승인 대기 ({pending.length})</h2>
        <div className="mt-3 space-y-3">
          {pending.length === 0 && <p className="text-sm text-text-gray">대기 중인 신청이 없습니다.</p>}
          {pending.map((a) => (
            <AdminApplicationRow key={a.id} application={a} />
          ))}
        </div>
      </section>

      <section className="mt-10">
        <h2 className="text-sm font-bold text-mid-gray">처리 완료</h2>
        <div className="mt-3 space-y-3">
          {others.map((a) => (
            <AdminApplicationRow key={a.id} application={a} readOnly />
          ))}
        </div>
      </section>
    </div>
  );
}
