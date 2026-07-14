"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useAuth } from "@/components/AuthProvider";
import { uploadImage } from "@/lib/uploadImage";
import { AppConfig } from "@/lib/config";
import { FormField, SubmitButton } from "@/components/AuthCard";

export default function OwnerApplyPage() {
  const router = useRouter();
  const { user, loading } = useAuth();
  const [form, setForm] = useState({
    businessNumber: "",
    storeName: "",
    ownerName: "",
    phone: "",
    address: "",
    detailAddress: "",
    category: "한식",
    description: "",
    openingHours: "",
    isTakeoutAvailable: false,
    isDeliveryAvailable: false,
  });
  const [licenseFile, setLicenseFile] = useState<File | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  useEffect(() => {
    if (!loading && !user) router.push("/login?error=" + encodeURIComponent("로그인 후 가게를 등록할 수 있습니다."));
  }, [loading, user, router]);

  function set<K extends keyof typeof form>(key: K, value: (typeof form)[K]) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!user) return;
    setError(null);

    if (!form.businessNumber.trim() || !form.storeName.trim() || !form.address.trim()) {
      setError("사업자등록번호, 가게명, 주소는 필수입니다.");
      return;
    }

    setSubmitting(true);
    const supabase = createClient();

    let licenseUrl: string | null = null;
    if (licenseFile) {
      const { url, error: uploadErr } = await uploadImage(supabase, "business-licenses", user.id, licenseFile);
      if (uploadErr) {
        setError(uploadErr);
        setSubmitting(false);
        return;
      }
      licenseUrl = url;
    }

    let lat: number | null = null;
    let lng: number | null = null;
    let geocodingStatus = "not_attempted";
    let geocodingError: string | null = null;
    try {
      const fullAddress = `${form.address} ${form.detailAddress}`.trim();
      const res = await fetch(`/api/geocode?query=${encodeURIComponent(fullAddress)}`);
      const json = await res.json();
      if (json.success) {
        lat = json.lat;
        lng = json.lng;
        geocodingStatus = "success";
      } else {
        geocodingStatus = "failed";
        geocodingError = json.error ?? null;
      }
    } catch {
      geocodingStatus = "failed";
      geocodingError = "지오코딩 요청 실패";
    }

    const { error: insertError } = await supabase.from("owner_store_applications").insert({
      user_id: user.id,
      business_number: form.businessNumber.trim(),
      store_name: form.storeName.trim(),
      owner_name: form.ownerName.trim() || null,
      phone: form.phone.trim() || null,
      address: form.address.trim(),
      detail_address: form.detailAddress.trim() || null,
      category: form.category,
      description: form.description.trim() || null,
      opening_hours: form.openingHours.trim() || null,
      is_takeout_available: form.isTakeoutAvailable,
      is_delivery_available: form.isDeliveryAvailable,
      business_license_image_url: licenseUrl,
      lat,
      lng,
      geocoding_status: geocodingStatus,
      geocoding_error: geocodingError,
    });

    setSubmitting(false);
    if (insertError) {
      setError("신청 접수 중 오류가 발생했습니다. 다시 시도해주세요.");
      return;
    }
    setDone(true);
  }

  if (loading || !user) return null;

  if (done) {
    return (
      <div className="mx-auto max-w-xl px-4 py-16 text-center sm:px-6">
        <p className="text-2xl">✅</p>
        <h1 className="mt-4 text-xl font-extrabold text-dark-ink">가게 등록 신청이 접수되었습니다</h1>
        <p className="mt-2 text-sm text-text-gray">관리자 검토 후 승인되면 지도와 추천 결과에 노출됩니다.</p>
        <button
          onClick={() => router.push("/owner")}
          className="mt-6 rounded-full bg-orange px-6 py-3 text-sm font-bold text-white hover:opacity-90"
        >
          내 가게 목록으로
        </button>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-xl px-4 py-10 sm:px-6">
      <h1 className="text-2xl font-black text-dark-ink">가게 등록 신청</h1>
      <p className="mt-2 text-sm text-text-gray">
        신청 후 관리자 검토를 거쳐 승인되면 주먹요리 추천과 주먹지도에 노출됩니다.{" "}
        <a href="/business-terms" target="_blank" className="font-semibold text-orange hover:underline">
          사장님 이용약관 보기
        </a>
      </p>

      <form onSubmit={handleSubmit} className="mt-6 space-y-4">
        <FormField label="사업자등록번호 *" required value={form.businessNumber} onChange={(e) => set("businessNumber", e.target.value)} />
        <FormField label="가게명 *" required value={form.storeName} onChange={(e) => set("storeName", e.target.value)} />
        <FormField label="대표자명" value={form.ownerName} onChange={(e) => set("ownerName", e.target.value)} />
        <FormField label="전화번호" value={form.phone} onChange={(e) => set("phone", e.target.value)} />
        <FormField label="주소 *" required value={form.address} onChange={(e) => set("address", e.target.value)} placeholder="도로명 주소" />
        <FormField label="상세 주소" value={form.detailAddress} onChange={(e) => set("detailAddress", e.target.value)} />

        <label className="block">
          <span className="mb-1.5 block text-sm font-semibold text-dark-ink">카테고리</span>
          <select
            value={form.category}
            onChange={(e) => set("category", e.target.value)}
            className="w-full rounded-xl border border-soft-gray bg-white px-4 py-3 text-sm outline-none focus:border-orange"
          >
            {AppConfig.categoryOptions.filter((c) => c !== "전체").map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </label>

        <FormField label="영업시간" value={form.openingHours} onChange={(e) => set("openingHours", e.target.value)} placeholder="예: 11:00~21:00" />

        <label className="block">
          <span className="mb-1.5 block text-sm font-semibold text-dark-ink">소개</span>
          <textarea
            value={form.description}
            onChange={(e) => set("description", e.target.value)}
            rows={3}
            className="w-full rounded-xl border border-soft-gray bg-white px-4 py-3 text-sm outline-none focus:border-orange"
          />
        </label>

        <div className="flex gap-4">
          <label className="flex items-center gap-2 text-sm text-dark-ink">
            <input
              type="checkbox"
              checked={form.isTakeoutAvailable}
              onChange={(e) => set("isTakeoutAvailable", e.target.checked)}
            />
            포장 가능
          </label>
          <label className="flex items-center gap-2 text-sm text-dark-ink">
            <input
              type="checkbox"
              checked={form.isDeliveryAvailable}
              onChange={(e) => set("isDeliveryAvailable", e.target.checked)}
            />
            배달 가능
          </label>
        </div>

        <label className="block">
          <span className="mb-1.5 block text-sm font-semibold text-dark-ink">사업자등록증 이미지 (선택)</span>
          <input
            type="file"
            accept="image/*"
            onChange={(e) => setLicenseFile(e.target.files?.[0] ?? null)}
            className="block w-full text-sm"
          />
        </label>

        {error && <p className="text-sm font-medium text-error">{error}</p>}
        <SubmitButton loading={submitting}>신청하기</SubmitButton>
      </form>
    </div>
  );
}
