"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { Report } from "@/types/database";

const STATUS_LABEL: Record<string, string> = { pending: "미처리", reviewed: "검토 중", resolved: "처리 완료" };

export function AdminReportRow({ report, reasonLabel }: { report: Report; reasonLabel: string }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);

  async function updateStatus(status: "reviewed" | "resolved") {
    setBusy(true);
    const supabase = createClient();
    await supabase.from("reports").update({ status }).eq("id", report.id);
    setBusy(false);
    router.refresh();
  }

  return (
    <div className="rounded-2xl border border-soft-gray bg-white p-5">
      <div className="flex items-center justify-between">
        <p className="font-bold text-dark-ink">{reasonLabel}</p>
        <span
          className={`rounded-full px-3 py-1 text-xs font-bold ${
            report.status === "pending" ? "bg-orange-light text-orange" : "bg-soft-gray text-mid-gray"
          }`}
        >
          {STATUS_LABEL[report.status]}
        </span>
      </div>
      {report.detail && <p className="mt-2 text-sm text-text-gray">{report.detail}</p>}
      <p className="mt-2 text-xs text-mid-gray">{new Date(report.created_at).toLocaleString("ko-KR")}</p>
      {report.status !== "resolved" && (
        <div className="mt-3 flex gap-2">
          {report.status === "pending" && (
            <button
              onClick={() => updateStatus("reviewed")}
              disabled={busy}
              className="rounded-lg border border-soft-gray px-4 py-2 text-xs font-bold text-dark-ink disabled:opacity-50"
            >
              검토 중으로 표시
            </button>
          )}
          <button
            onClick={() => updateStatus("resolved")}
            disabled={busy}
            className="rounded-lg bg-orange px-4 py-2 text-xs font-bold text-white disabled:opacity-50"
          >
            처리 완료
          </button>
        </div>
      )}
    </div>
  );
}
