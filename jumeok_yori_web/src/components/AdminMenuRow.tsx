"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { MenuItem } from "@/types/database";

export function AdminMenuRow({ menu, restaurantName }: { menu: MenuItem; restaurantName: string }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState("");
  const [showReject, setShowReject] = useState(false);

  async function handleApprove() {
    if (!confirm(`"${menu.name}" 메뉴를 승인하시겠습니까?`)) return;
    setBusy(true);
    const supabase = createClient();
    await supabase
      .from("menu_items")
      .update({ approval_status: "approved", display_status: "approved" })
      .eq("id", menu.id);
    setBusy(false);
    router.refresh();
  }

  async function handleReject() {
    setBusy(true);
    const supabase = createClient();
    await supabase.from("menu_items").update({ approval_status: "rejected", display_status: "hidden" }).eq("id", menu.id);
    setBusy(false);
    router.refresh();
  }

  return (
    <div className="rounded-2xl border border-soft-gray bg-white p-5">
      <p className="font-bold text-dark-ink">{menu.name}</p>
      <p className="mt-1 text-xs text-text-gray">
        {restaurantName} · {menu.price.toLocaleString("ko-KR")}원 · {menu.category}
      </p>
      {menu.description && <p className="mt-1 text-xs text-text-gray">{menu.description}</p>}
      <div className="mt-3 flex gap-2">
        <button onClick={handleApprove} disabled={busy} className="rounded-lg bg-orange px-4 py-2 text-xs font-bold text-white disabled:opacity-50">
          승인
        </button>
        <button onClick={() => setShowReject((v) => !v)} disabled={busy} className="rounded-lg border border-error/40 px-4 py-2 text-xs font-bold text-error">
          반려
        </button>
      </div>
      {showReject && (
        <div className="mt-2 flex gap-2">
          <input
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="반려 사유 (선택)"
            className="flex-1 rounded-lg border border-soft-gray px-3 py-2 text-xs outline-none focus:border-orange"
          />
          <button onClick={handleReject} disabled={busy} className="rounded-lg bg-error px-4 py-2 text-xs font-bold text-white disabled:opacity-50">
            반려 확정
          </button>
        </div>
      )}
    </div>
  );
}
