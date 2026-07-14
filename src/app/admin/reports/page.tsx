import type { Metadata } from "next";
import { requireAdmin } from "@/lib/requireAdmin";
import type { Report } from "@/types/database";
import { AdminReportRow } from "@/components/AdminReportRow";

export const metadata: Metadata = { title: "신고 처리" };

const REASON_LABEL: Record<string, string> = {
  false_info: "허위 정보",
  spam: "스팸",
  inappropriate: "부적절한 콘텐츠",
  defamation: "명예훼손",
  other: "기타",
};

export default async function AdminReportsPage() {
  const { supabase } = await requireAdmin();
  const { data } = await supabase.from("reports").select("*").order("created_at", { ascending: false });
  const reports = (data as Report[]) ?? [];

  return (
    <div className="mx-auto max-w-4xl px-4 py-10 sm:px-6">
      <h1 className="text-2xl font-black text-dark-ink sm:text-3xl">신고 처리</h1>
      <div className="mt-6 space-y-3">
        {reports.length === 0 && <p className="text-sm text-text-gray">접수된 신고가 없습니다.</p>}
        {reports.map((r) => (
          <AdminReportRow key={r.id} report={r} reasonLabel={REASON_LABEL[r.reason] ?? r.reason} />
        ))}
      </div>
    </div>
  );
}
