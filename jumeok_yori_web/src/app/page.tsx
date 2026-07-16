import Link from "next/link";
import Image from "next/image";
import { createClient } from "@/lib/supabase/server";
import type { Restaurant } from "@/types/database";

async function getPreviewRestaurants(): Promise<Restaurant[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("restaurants")
    .select("*")
    .eq("display_status", "approved")
    .order("created_at", { ascending: false })
    .limit(6);
  return (data as Restaurant[]) ?? [];
}

const FEATURES = [
  {
    title: "위치 기반 추천",
    desc: "현재 위치 또는 직접 정한 기준 위치를 중심으로 거리 안의 메뉴만 골라드려요.",
    icon: "📍",
  },
  {
    title: "조건 필터",
    desc: "거리, 가격, 음식 종류, 혼밥·포장·배달 여부까지 원하는 조건만 정하세요.",
    icon: "🎛️",
  },
  {
    title: "주먹지도",
    desc: "승인된 등록 가게를 지도에서 한눈에 보고 상세 정보를 확인할 수 있어요.",
    icon: "🗺️",
  },
  {
    title: "사장님 등록",
    desc: "사장님은 가게와 메뉴를 등록해 주먹요리 추천에 노출시킬 수 있어요.",
    icon: "🏪",
  },
];

export default async function Home() {
  const restaurants = await getPreviewRestaurants();

  return (
    <div>
      {/* Hero */}
      <section className="border-b border-soft-gray bg-gradient-to-b from-orange-light to-ivory">
        <div className="mx-auto flex max-w-6xl flex-col items-start gap-8 px-4 py-16 sm:px-6 sm:py-24 lg:flex-row lg:items-center lg:justify-between">
          <div className="max-w-xl">
            <p className="mb-3 text-sm font-bold text-orange">주는 대로 먹는 요리</p>
            <h1 className="text-4xl font-black leading-tight text-dark-ink sm:text-5xl">
              고민 끝.
              <br />
              오늘은 이거.
            </h1>
            <p className="mt-5 text-base leading-relaxed text-text-gray sm:text-lg">
              매일 반복되는 점심·저녁 메뉴 고민, 이제 주먹요리에게 맡겨보세요.
              거리, 가격, 조건만 정하면 오늘 먹을 메뉴를 대신 골라드립니다.
            </p>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <Link
                href="/recommend"
                className="rounded-full bg-orange px-8 py-4 text-center text-base font-bold text-white shadow-sm transition hover:opacity-90"
              >
                오늘 메뉴 뽑기
              </Link>
              <Link
                href="/map"
                className="rounded-full border border-soft-gray bg-white px-8 py-4 text-center text-base font-bold text-dark-ink transition hover:border-orange hover:text-orange"
              >
                주먹지도 보기
              </Link>
            </div>
            <p className="mt-4 text-xs text-mid-gray">
              위치 권한을 허용하면 내 주변 기준으로, 거부해도 기준 위치를 직접 설정해 이용할 수 있어요.
            </p>
          </div>

          <div className="w-full max-w-sm shrink-0">
            <div className="overflow-hidden rounded-3xl border border-soft-gray bg-white p-6 shadow-sm">
              <Image
                src="/logo-square.png"
                alt="주먹요리 로고"
                width={400}
                height={400}
                className="mx-auto h-40 w-40 object-contain"
                priority
              />
              <div className="mt-4 space-y-2 text-center">
                <p className="text-sm font-bold text-dark-ink">오늘의 추천 예시</p>
                <p className="text-2xl font-black text-orange">김치제육덮밥</p>
                <p className="text-sm text-text-gray">한식 · 8,000~11,000원 · 혼밥 OK</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
        <h2 className="text-2xl font-extrabold text-dark-ink sm:text-3xl">주먹요리가 하는 일</h2>
        <div className="mt-8 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {FEATURES.map((f) => (
            <div key={f.title} className="rounded-2xl border border-soft-gray bg-white p-6">
              <div className="text-3xl">{f.icon}</div>
              <h3 className="mt-4 text-base font-bold text-dark-ink">{f.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-text-gray">{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Registered restaurants preview */}
      <section className="border-t border-soft-gray bg-white">
        <div className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
          <div className="flex items-center justify-between">
            <h2 className="text-2xl font-extrabold text-dark-ink sm:text-3xl">등록된 가게</h2>
            <Link href="/restaurants" className="text-sm font-semibold text-orange hover:underline">
              전체 보기 →
            </Link>
          </div>

          {restaurants.length === 0 ? (
            <div className="mt-8 rounded-2xl border border-dashed border-soft-gray p-10 text-center text-text-gray">
              아직 등록된 가게가 없어요. 기본 추천 메뉴로 오늘의 메뉴를 뽑아보세요.
            </div>
          ) : (
            <div className="mt-8 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {restaurants.map((r) => (
                <Link
                  key={r.id}
                  href={`/restaurants/${r.id}`}
                  className="rounded-2xl border border-soft-gray bg-ivory p-5 transition hover:border-orange"
                >
                  <p className="text-xs font-bold text-orange">{r.category ?? "기타"}</p>
                  <h3 className="mt-1 text-lg font-bold text-dark-ink">{r.name}</h3>
                  <p className="mt-2 line-clamp-2 text-sm text-text-gray">{r.address}</p>
                </Link>
              ))}
            </div>
          )}
        </div>
      </section>

      {/* Owner CTA */}
      <section className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
        <div className="rounded-3xl bg-dark-ink px-8 py-12 text-center sm:px-16">
          <h2 className="text-2xl font-extrabold text-white sm:text-3xl">사장님이신가요?</h2>
          <p className="mt-3 text-sm leading-relaxed text-white/70 sm:text-base">
            가게와 메뉴를 등록하면 관리자 승인 후 주먹요리 추천과 주먹지도에 노출됩니다.
          </p>
          <Link
            href="/owner"
            className="mt-6 inline-block rounded-full bg-orange px-8 py-3 text-sm font-bold text-white hover:opacity-90"
          >
            내 가게 등록하기
          </Link>
        </div>
      </section>

      {/* App download */}
      <section className="border-t border-soft-gray bg-white">
        <div className="mx-auto max-w-6xl px-4 py-12 text-center sm:px-6">
          <p className="text-sm font-bold text-orange">모바일 앱</p>
          <h2 className="mt-2 text-xl font-extrabold text-dark-ink">주먹요리 앱은 Google Play 출시 준비 중입니다</h2>
          <p className="mt-2 text-sm text-text-gray">
            웹에서 만든 계정은 앱 출시 후 동일하게 로그인해 이용할 수 있습니다.
          </p>
        </div>
      </section>
    </div>
  );
}
