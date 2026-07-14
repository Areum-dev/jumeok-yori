"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { Restaurant } from "@/types/database";

export function AdminRestaurantRow({ restaurant }: { restaurant: Restaurant }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);

  async function setDisplayStatus(status: "approved" | "suspended") {
    const verb = status === "approved" ? "노출 재개" : "비공개 처리";
    if (!confirm(`"${restaurant.name}" 가게를 ${verb}하시겠습니까?`)) return;
    setBusy(true);
    const supabase = createClient();
    await supabase.from("restaurants").update({ display_status: status }).eq("id", restaurant.id);
    setBusy(false);
    router.refresh();
  }

  return (
    <div className="flex items-center justify-between rounded-2xl border border-soft-gray bg-white p-5">
      <div className="min-w-0">
        <div className="flex items-center gap-2">
          <p className="truncate font-bold text-dark-ink">{restaurant.name}</p>
          <span
            className={`shrink-0 rounded-full px-2.5 py-0.5 text-[10px] font-bold ${
              restaurant.display_status === "approved" ? "bg-green-50 text-success" : "bg-soft-gray text-mid-gray"
            }`}
          >
            {restaurant.display_status === "approved" ? "노출 중" : "비공개"}
          </span>
        </div>
        <p className="mt-1 truncate text-xs text-text-gray">{restaurant.address}</p>
      </div>
      <div className="flex shrink-0 gap-2">
        <Link
          href={`/restaurants/${restaurant.id}`}
          className="rounded-lg border border-soft-gray px-3 py-2 text-xs font-semibold text-dark-ink hover:border-orange"
        >
          보기
        </Link>
        {restaurant.display_status === "approved" ? (
          <button
            onClick={() => setDisplayStatus("suspended")}
            disabled={busy}
            className="rounded-lg border border-error/40 px-3 py-2 text-xs font-semibold text-error disabled:opacity-50"
          >
            비공개
          </button>
        ) : (
          <button
            onClick={() => setDisplayStatus("approved")}
            disabled={busy}
            className="rounded-lg bg-orange px-3 py-2 text-xs font-semibold text-white disabled:opacity-50"
          >
            노출 재개
          </button>
        )}
      </div>
    </div>
  );
}
