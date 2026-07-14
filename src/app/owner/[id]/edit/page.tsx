"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useAuth } from "@/components/AuthProvider";
import { uploadImage } from "@/lib/uploadImage";
import { AppConfig } from "@/lib/config";
import { FormField, SubmitButton } from "@/components/AuthCard";
import type { Restaurant } from "@/types/database";

export default function EditRestaurantPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();

  const [restaurant, setRestaurant] = useState<Restaurant | null>(null);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState({
    name: "",
    phone: "",
    address: "",
    detailAddress: "",
    category: "한식",
    description: "",
    openingHours: "",
    isTakeoutAvailable: false,
    isDeliveryAvailable: false,
  });
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  useEffect(() => {
    (async () => {
      const supabase = createClient();
      const { data } = await supabase.from("restaurants").select("*").eq("id", params.id).maybeSingle();
      if (!data) {
        setLoading(false);
        return;
      }
      const r = data as Restaurant;
      setRestaurant(r);
      setForm({
        name: r.name,
        phone: r.phone ?? "",
        address: r.address ?? "",
        detailAddress: r.detail_address ?? "",
        category: r.category ?? "한식",
        description: r.description ?? "",
        openingHours: r.opening_hours ?? "",
        isTakeoutAvailable: r.is_takeout_available,
        isDeliveryAvailable: r.is_delivery_available,
      });
      setLoading(false);
    })();
  }, [params.id]);

  function set<K extends keyof typeof form>(key: K, value: (typeof form)[K]) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!user || !restaurant) return;
    setSaving(true);
    setError(null);

    const supabase = createClient();
    let imageUrl = restaurant.image_url;
    if (imageFile) {
      const { url, error: uploadErr } = await uploadImage(supabase, "menu-images", user.id, imageFile);
      if (uploadErr) {
        setError(uploadErr);
        setSaving(false);
        return;
      }
      imageUrl = url;
    }

    const { error: updateError } = await supabase
      .from("restaurants")
      .update({
        name: form.name.trim(),
        phone: form.phone.trim() || null,
        address: form.address.trim(),
        detail_address: form.detailAddress.trim() || null,
        category: form.category,
        description: form.description.trim() || null,
        opening_hours: form.openingHours.trim() || null,
        is_takeout_available: form.isTakeoutAvailable,
        is_delivery_available: form.isDeliveryAvailable,
        image_url: imageUrl,
      })
      .eq("id", restaurant.id);

    setSaving(false);
    if (updateError) {
      setError("저장 중 오류가 발생했습니다.");
      return;
    }
    setDone(true);
    setTimeout(() => router.push(`/owner/${restaurant.id}`), 800);
  }

  if (authLoading || loading) return null;
  if (!restaurant) return <p className="mx-auto max-w-xl px-4 py-16 text-center text-text-gray">가게 정보를 찾을 수 없습니다.</p>;
  if (restaurant.owner_id !== user?.id) {
    router.push("/owner");
    return null;
  }

  return (
    <div className="mx-auto max-w-xl px-4 py-10 sm:px-6">
      <h1 className="text-2xl font-black text-dark-ink">가게 정보 수정</h1>
      <form onSubmit={handleSubmit} className="mt-6 space-y-4">
        <FormField label="가게명" required value={form.name} onChange={(e) => set("name", e.target.value)} />
        <FormField label="전화번호" value={form.phone} onChange={(e) => set("phone", e.target.value)} />
        <FormField label="주소" required value={form.address} onChange={(e) => set("address", e.target.value)} />
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

        <FormField label="영업시간" value={form.openingHours} onChange={(e) => set("openingHours", e.target.value)} />

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
            <input type="checkbox" checked={form.isTakeoutAvailable} onChange={(e) => set("isTakeoutAvailable", e.target.checked)} />
            포장 가능
          </label>
          <label className="flex items-center gap-2 text-sm text-dark-ink">
            <input type="checkbox" checked={form.isDeliveryAvailable} onChange={(e) => set("isDeliveryAvailable", e.target.checked)} />
            배달 가능
          </label>
        </div>

        <label className="block">
          <span className="mb-1.5 block text-sm font-semibold text-dark-ink">대표 이미지</span>
          <input type="file" accept="image/*" onChange={(e) => setImageFile(e.target.files?.[0] ?? null)} className="block w-full text-sm" />
        </label>

        {error && <p className="text-sm font-medium text-error">{error}</p>}
        {done && <p className="text-sm font-medium text-success">저장되었습니다.</p>}
        <SubmitButton loading={saving}>저장</SubmitButton>
      </form>
    </div>
  );
}
