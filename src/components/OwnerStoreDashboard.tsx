"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { uploadImage } from "@/lib/uploadImage";
import { AppConfig } from "@/lib/config";
import { FileInput } from "@/components/FileInput";
import type { MenuItem, Restaurant } from "@/types/database";

const STATUS_LABEL: Record<string, string> = {
  pending: "검수 대기",
  approved: "승인됨",
  rejected: "반려됨",
  suspended: "정지됨",
  hidden: "비공개",
};

interface Stats {
  todayDraws: number;
  totalDraws: number;
  totalViews: number;
  savedCount: number;
  totalMenus: number;
  visibleMenus: number;
}

async function loadStats(restaurantId: string, ownerId: string, menuIds: string[]): Promise<Stats> {
  const supabase = createClient();
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const [todayDraws, totalDraws, totalViews, saved, totalMenus, visibleMenus] = await Promise.all([
    supabase
      .from("analytics_events")
      .select("id", { count: "exact", head: true })
      .eq("owner_id", ownerId)
      .eq("restaurant_id", restaurantId)
      .eq("event_type", "recommendation_drawn")
      .gte("created_at", todayStart.toISOString()),
    supabase
      .from("analytics_events")
      .select("id", { count: "exact", head: true })
      .eq("owner_id", ownerId)
      .eq("restaurant_id", restaurantId)
      .eq("event_type", "recommendation_drawn"),
    supabase
      .from("analytics_events")
      .select("id", { count: "exact", head: true })
      .eq("owner_id", ownerId)
      .eq("restaurant_id", restaurantId)
      .eq("event_type", "restaurant_viewed"),
    menuIds.length > 0
      ? supabase.from("saved_menu_items").select("id", { count: "exact", head: true }).in("menu_item_id", menuIds)
      : Promise.resolve({ count: 0 }),
    supabase.from("menu_items").select("id", { count: "exact", head: true }).eq("restaurant_id", restaurantId),
    supabase
      .from("menu_items")
      .select("id", { count: "exact", head: true })
      .eq("restaurant_id", restaurantId)
      .eq("display_status", "approved")
      .eq("is_available", true),
  ]);

  return {
    todayDraws: todayDraws.count ?? 0,
    totalDraws: totalDraws.count ?? 0,
    totalViews: totalViews.count ?? 0,
    savedCount: saved.count ?? 0,
    totalMenus: totalMenus.count ?? 0,
    visibleMenus: visibleMenus.count ?? 0,
  };
}

export function OwnerStoreDashboard({
  restaurant,
  initialMenus,
  ownerId,
}: {
  restaurant: Restaurant;
  initialMenus: MenuItem[];
  ownerId: string;
}) {
  const [menus, setMenus] = useState<MenuItem[]>(initialMenus);
  const [stats, setStats] = useState<Stats | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [editingMenu, setEditingMenu] = useState<MenuItem | null>(null);

  useEffect(() => {
    loadStats(
      restaurant.id,
      ownerId,
      menus.map((m) => m.id),
    ).then(setStats);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [restaurant.id, ownerId, menus.length]);

  async function refreshMenus() {
    const supabase = createClient();
    const { data } = await supabase
      .from("menu_items")
      .select("*")
      .eq("restaurant_id", restaurant.id)
      .order("created_at", { ascending: false });
    setMenus((data as MenuItem[]) ?? []);
  }

  async function handleDelete(menuId: string) {
    if (!confirm("이 메뉴를 삭제하시겠습니까?")) return;
    const supabase = createClient();
    await supabase.from("menu_items").delete().eq("id", menuId);
    await refreshMenus();
  }

  async function handleToggleAvailable(menu: MenuItem) {
    const supabase = createClient();
    await supabase.from("menu_items").update({ is_available: !menu.is_available }).eq("id", menu.id);
    await refreshMenus();
  }

  return (
    <div className="mx-auto max-w-4xl px-4 py-10 sm:px-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-black text-dark-ink">{restaurant.name}</h1>
            <span
              className={`rounded-full px-3 py-1 text-xs font-bold ${
                restaurant.display_status === "approved" ? "bg-green-50 text-success" : "bg-soft-gray text-mid-gray"
              }`}
            >
              {restaurant.display_status === "approved" ? "노출 중" : STATUS_LABEL[restaurant.verification_status]}
            </span>
          </div>
          <p className="mt-1 text-sm text-text-gray">{restaurant.address}</p>
        </div>
        <Link
          href={`/owner/${restaurant.id}/edit`}
          className="rounded-full border border-soft-gray px-4 py-2 text-xs font-bold text-dark-ink hover:border-orange hover:text-orange"
        >
          가게 정보 수정
        </Link>
      </div>

      <div className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
        {[
          ["오늘 추천", stats?.todayDraws],
          ["누적 추천", stats?.totalDraws],
          ["조회수", stats?.totalViews],
          ["저장 수", stats?.savedCount],
          ["전체 메뉴", stats?.totalMenus],
          ["노출 메뉴", stats?.visibleMenus],
        ].map(([label, value]) => (
          <div key={label as string} className="rounded-2xl border border-soft-gray bg-white p-4 text-center">
            <p className="text-xs text-mid-gray">{label}</p>
            <p className="mt-1 text-xl font-black text-orange">{value ?? 0}</p>
          </div>
        ))}
      </div>

      <div className="mt-10 flex items-center justify-between">
        <h2 className="text-lg font-extrabold text-dark-ink">메뉴 관리</h2>
        <button
          onClick={() => {
            setEditingMenu(null);
            setShowForm(true);
          }}
          className="rounded-full bg-orange px-4 py-2 text-xs font-bold text-white hover:opacity-90"
        >
          + 메뉴 추가
        </button>
      </div>

      {showForm && (
        <MenuForm
          restaurantId={restaurant.id}
          ownerId={ownerId}
          menu={editingMenu}
          onCancel={() => setShowForm(false)}
          onSaved={async () => {
            setShowForm(false);
            await refreshMenus();
          }}
        />
      )}

      <div className="mt-4 space-y-3">
        {menus.length === 0 && !showForm && (
          <p className="rounded-2xl border border-dashed border-soft-gray bg-white p-8 text-center text-sm text-text-gray">
            등록된 메뉴가 없어요. 메뉴를 추가해보세요.
          </p>
        )}
        {menus.map((m) => (
          <div key={m.id} className="flex items-center gap-4 rounded-2xl border border-soft-gray bg-white p-4">
            <div className="relative h-16 w-16 shrink-0 overflow-hidden rounded-xl bg-orange-light">
              {m.image_url ? (
                <Image src={m.image_url} alt={m.name} fill className="object-cover" />
              ) : (
                <div className="flex h-full items-center justify-center text-xl">🍚</div>
              )}
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2">
                <p className="truncate text-sm font-bold text-dark-ink">{m.name}</p>
                <span className="shrink-0 rounded-full bg-orange-light px-2 py-0.5 text-[10px] font-bold text-orange">
                  {STATUS_LABEL[m.approval_status]}
                </span>
                {!m.is_available && (
                  <span className="shrink-0 rounded-full bg-soft-gray px-2 py-0.5 text-[10px] font-bold text-mid-gray">
                    품절
                  </span>
                )}
              </div>
              <p className="mt-0.5 text-xs text-text-gray">{m.price.toLocaleString("ko-KR")}원 · {m.category}</p>
            </div>
            <div className="flex shrink-0 gap-1.5">
              <button
                onClick={() => handleToggleAvailable(m)}
                className="rounded-lg border border-soft-gray px-2.5 py-1.5 text-xs font-semibold text-dark-ink hover:border-orange"
              >
                {m.is_available ? "품절 처리" : "판매 재개"}
              </button>
              <button
                onClick={() => {
                  setEditingMenu(m);
                  setShowForm(true);
                }}
                className="rounded-lg border border-soft-gray px-2.5 py-1.5 text-xs font-semibold text-dark-ink hover:border-orange"
              >
                수정
              </button>
              <button
                onClick={() => handleDelete(m.id)}
                className="rounded-lg border border-error/40 px-2.5 py-1.5 text-xs font-semibold text-error"
              >
                삭제
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function MenuForm({
  restaurantId,
  ownerId,
  menu,
  onCancel,
  onSaved,
}: {
  restaurantId: string;
  ownerId: string;
  menu: MenuItem | null;
  onCancel: () => void;
  onSaved: () => void;
}) {
  const [name, setName] = useState(menu?.name ?? "");
  const [price, setPrice] = useState(menu?.price?.toString() ?? "");
  const [category, setCategory] = useState(menu?.category ?? "한식");
  const [description, setDescription] = useState(menu?.description ?? "");
  const [isSoloFriendly, setIsSoloFriendly] = useState(menu?.is_solo_friendly ?? false);
  const [isTakeout, setIsTakeout] = useState(menu?.is_takeout_available ?? false);
  const [isDelivery, setIsDelivery] = useState(menu?.is_delivery_available ?? false);
  const [isVegan, setIsVegan] = useState(menu?.is_vegan_option ?? false);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    const priceNum = Number(price);
    if (!name.trim() || !priceNum || priceNum <= 0) {
      setError("메뉴명과 올바른 가격을 입력해주세요.");
      return;
    }

    setSaving(true);
    const supabase = createClient();

    let imageUrl = menu?.image_url ?? null;
    if (imageFile) {
      const { url, error: uploadErr } = await uploadImage(supabase, "menu-images", ownerId, imageFile);
      if (uploadErr) {
        setError(uploadErr);
        setSaving(false);
        return;
      }
      imageUrl = url;
    }

    const payload = {
      restaurant_id: restaurantId,
      owner_id: ownerId,
      name: name.trim(),
      description: description.trim() || null,
      price: priceNum,
      category,
      image_url: imageUrl,
      is_solo_friendly: isSoloFriendly,
      is_takeout_available: isTakeout,
      is_delivery_available: isDelivery,
      is_vegan_option: isVegan,
    };

    const result = menu
      ? await supabase.from("menu_items").update(payload).eq("id", menu.id)
      : await supabase.from("menu_items").insert(payload);

    setSaving(false);
    if (result.error) {
      setError("저장 중 오류가 발생했습니다.");
      return;
    }
    onSaved();
  }

  return (
    <form onSubmit={handleSubmit} className="mt-4 space-y-3 rounded-2xl border border-orange bg-white p-5">
      <h3 className="text-sm font-bold text-dark-ink">{menu ? "메뉴 수정" : "새 메뉴"}</h3>
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <input
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="메뉴명"
          className="rounded-xl border border-soft-gray px-3 py-2.5 text-sm outline-none focus:border-orange"
        />
        <input
          type="number"
          value={price}
          onChange={(e) => setPrice(e.target.value)}
          placeholder="가격"
          className="rounded-xl border border-soft-gray px-3 py-2.5 text-sm outline-none focus:border-orange"
        />
        <select
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          className="rounded-xl border border-soft-gray px-3 py-2.5 text-sm outline-none focus:border-orange"
        >
          {AppConfig.categoryOptions.filter((c) => c !== "전체").map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>
      </div>
      <FileInput label="메뉴 이미지" onChange={setImageFile} />
      <textarea
        value={description}
        onChange={(e) => setDescription(e.target.value)}
        placeholder="메뉴 설명"
        rows={2}
        className="w-full rounded-xl border border-soft-gray px-3 py-2.5 text-sm outline-none focus:border-orange"
      />
      <div className="flex flex-wrap gap-4 text-xs">
        <label className="flex items-center gap-1.5"><input type="checkbox" checked={isSoloFriendly} onChange={(e) => setIsSoloFriendly(e.target.checked)} />혼밥 OK</label>
        <label className="flex items-center gap-1.5"><input type="checkbox" checked={isTakeout} onChange={(e) => setIsTakeout(e.target.checked)} />포장 가능</label>
        <label className="flex items-center gap-1.5"><input type="checkbox" checked={isDelivery} onChange={(e) => setIsDelivery(e.target.checked)} />배달 가능</label>
        <label className="flex items-center gap-1.5"><input type="checkbox" checked={isVegan} onChange={(e) => setIsVegan(e.target.checked)} />비건 옵션</label>
      </div>
      {error && <p className="text-xs font-medium text-error">{error}</p>}
      <div className="flex gap-2">
        <button type="submit" disabled={saving} className="rounded-xl bg-orange px-5 py-2.5 text-xs font-bold text-white disabled:opacity-50">
          {saving ? "저장 중..." : "저장"}
        </button>
        <button type="button" onClick={onCancel} className="rounded-xl border border-soft-gray px-5 py-2.5 text-xs font-bold text-dark-ink">
          취소
        </button>
      </div>
    </form>
  );
}
