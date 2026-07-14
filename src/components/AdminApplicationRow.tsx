"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { OwnerStoreApplication } from "@/types/database";

const STATUS_LABEL: Record<string, string> = {
  pending: "검수 대기",
  approved: "승인됨",
  rejected: "반려됨",
  suspended: "정지됨",
};

export function AdminApplicationRow({
  application,
  readOnly = false,
}: {
  application: OwnerStoreApplication;
  readOnly?: boolean;
}) {
  const router = useRouter();
  const [lat, setLat] = useState(application.lat?.toString() ?? "");
  const [lng, setLng] = useState(application.lng?.toString() ?? "");
  const [rejectNote, setRejectNote] = useState("");
  const [showReject, setShowReject] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleApprove() {
    if (!confirm(`"${application.store_name}" 가게 등록을 승인하시겠습니까?`)) return;
    setBusy(true);
    setError(null);
    const supabase = createClient();

    const finalLat = lat ? Number(lat) : application.lat;
    const finalLng = lng ? Number(lng) : application.lng;

    const restaurantData = {
      owner_id: application.user_id,
      business_number: application.business_number,
      name: application.store_name,
      owner_name: application.owner_name,
      phone: application.phone,
      address: application.address,
      detail_address: application.detail_address,
      category: application.category,
      description: application.description,
      opening_hours: application.opening_hours,
      is_takeout_available: application.is_takeout_available,
      is_delivery_available: application.is_delivery_available,
      source: "owner_registered",
      verification_status: "approved" as const,
      display_status: "approved" as const,
      ...(finalLat && finalLat !== 0 ? { lat: finalLat } : {}),
      ...(finalLng && finalLng !== 0 ? { lng: finalLng } : {}),
    };

    let restaurantId = application.restaurant_id;
    if (restaurantId) {
      await supabase.from("restaurants").update(restaurantData).eq("id", restaurantId);
    } else {
      const { data: inserted, error: insertError } = await supabase
        .from("restaurants")
        .insert(restaurantData)
        .select()
        .single();
      if (insertError || !inserted) {
        setError("가게 생성 중 오류가 발생했습니다.");
        setBusy(false);
        return;
      }
      restaurantId = inserted.id;
    }

    await supabase
      .from("owner_store_applications")
      .update({ status: "approved", restaurant_id: restaurantId, reviewed_at: new Date().toISOString() })
      .eq("id", application.id);

    if (application.user_id) {
      await supabase.from("profiles").update({ role: "owner" }).eq("id", application.user_id);
    }

    setBusy(false);
    router.refresh();
  }

  async function handleReject() {
    if (!rejectNote.trim()) {
      setError("반려 사유를 입력해주세요.");
      return;
    }
    setBusy(true);
    setError(null);
    const supabase = createClient();
    await supabase
      .from("owner_store_applications")
      .update({ status: "rejected", admin_note: rejectNote.trim(), reviewed_at: new Date().toISOString() })
      .eq("id", application.id);
    setBusy(false);
    router.refresh();
  }

  return (
    <div className="rounded-2xl border border-soft-gray bg-white p-5">
      <div className="flex items-center justify-between">
        <p className="font-bold text-dark-ink">{application.store_name}</p>
        <span
          className={`rounded-full px-3 py-1 text-xs font-bold ${
            application.status === "rejected"
              ? "bg-red-50 text-error"
              : application.status === "approved"
                ? "bg-green-50 text-success"
                : "bg-orange-light text-orange"
          }`}
        >
          {STATUS_LABEL[application.status] ?? application.status}
        </span>
      </div>
      <p className="mt-1 text-xs text-text-gray">
        사업자등록번호 {application.business_number} · {application.category ?? "미분류"}
      </p>
      <p className="mt-1 text-xs text-text-gray">{application.address} {application.detail_address}</p>
      {application.phone && <p className="mt-1 text-xs text-text-gray">📞 {application.phone}</p>}
      {application.business_license_image_url && (
        <a
          href={application.business_license_image_url}
          target="_blank"
          rel="noopener noreferrer"
          className="mt-2 inline-block text-xs font-semibold text-orange hover:underline"
        >
          사업자등록증 이미지 보기
        </a>
      )}
      {application.geocoding_status === "failed" && (
        <p className="mt-1 text-xs text-error">지오코딩 실패: {application.geocoding_error ?? "좌표를 찾지 못했습니다"}</p>
      )}
      {application.admin_note && <p className="mt-2 text-xs text-error">처리 메모: {application.admin_note}</p>}

      {!readOnly && application.status === "pending" && (
        <>
          <div className="mt-3 grid grid-cols-2 gap-2">
            <input
              value={lat}
              onChange={(e) => setLat(e.target.value)}
              placeholder="위도 (lat)"
              className="rounded-lg border border-soft-gray px-3 py-2 text-xs outline-none focus:border-orange"
            />
            <input
              value={lng}
              onChange={(e) => setLng(e.target.value)}
              placeholder="경도 (lng)"
              className="rounded-lg border border-soft-gray px-3 py-2 text-xs outline-none focus:border-orange"
            />
          </div>
          {error && <p className="mt-2 text-xs font-medium text-error">{error}</p>}
          <div className="mt-3 flex gap-2">
            <button
              onClick={handleApprove}
              disabled={busy}
              className="rounded-lg bg-orange px-4 py-2 text-xs font-bold text-white disabled:opacity-50"
            >
              승인
            </button>
            <button
              onClick={() => setShowReject((v) => !v)}
              disabled={busy}
              className="rounded-lg border border-error/40 px-4 py-2 text-xs font-bold text-error"
            >
              반려
            </button>
          </div>
          {showReject && (
            <div className="mt-2 flex gap-2">
              <input
                value={rejectNote}
                onChange={(e) => setRejectNote(e.target.value)}
                placeholder="반려 사유"
                className="flex-1 rounded-lg border border-soft-gray px-3 py-2 text-xs outline-none focus:border-orange"
              />
              <button
                onClick={handleReject}
                disabled={busy}
                className="rounded-lg bg-error px-4 py-2 text-xs font-bold text-white disabled:opacity-50"
              >
                반려 확정
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
