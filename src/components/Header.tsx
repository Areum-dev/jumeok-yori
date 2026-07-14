"use client";

import Link from "next/link";
import { useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "@/components/AuthProvider";
import { createClient } from "@/lib/supabase/client";

const NAV_LINKS = [
  { href: "/recommend", label: "메뉴 추천" },
  { href: "/map", label: "지도" },
  { href: "/restaurants", label: "음식점" },
  { href: "/owner", label: "사장님" },
  { href: "/support", label: "고객지원" },
];

export function Header() {
  const { user, profile, loading, isAdmin } = useAuth();
  const pathname = usePathname();
  const router = useRouter();
  const [menuOpen, setMenuOpen] = useState(false);

  async function handleSignOut() {
    const supabase = createClient();
    await supabase.auth.signOut();
    setMenuOpen(false);
    router.push("/");
    router.refresh();
  }

  return (
    <header className="sticky top-0 z-50 border-b border-soft-gray bg-ivory/95 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4 sm:px-6">
        <Link href="/" className="flex items-center gap-2 text-lg font-extrabold text-dark-ink">
          <span className="flex h-9 w-9 items-center justify-center rounded-full bg-orange text-white">주</span>
          주먹요리
        </Link>

        <nav className="hidden items-center gap-6 md:flex">
          {NAV_LINKS.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className={`text-sm font-semibold transition-colors hover:text-orange ${
                pathname.startsWith(link.href) ? "text-orange" : "text-dark-ink"
              }`}
            >
              {link.label}
            </Link>
          ))}
          {isAdmin && (
            <Link
              href="/admin"
              className={`text-sm font-semibold transition-colors hover:text-orange ${
                pathname.startsWith("/admin") ? "text-orange" : "text-dark-ink"
              }`}
            >
              관리자
            </Link>
          )}
        </nav>

        <div className="hidden items-center gap-3 md:flex">
          {loading ? null : user ? (
            <>
              <Link
                href="/mypage"
                className="text-sm font-semibold text-dark-ink hover:text-orange"
              >
                {profile?.display_name || user.email}
              </Link>
              <button
                onClick={handleSignOut}
                className="rounded-full border border-soft-gray px-4 py-2 text-sm font-semibold text-dark-ink hover:border-orange hover:text-orange"
              >
                로그아웃
              </button>
            </>
          ) : (
            <>
              <Link
                href="/login"
                className="text-sm font-semibold text-dark-ink hover:text-orange"
              >
                로그인
              </Link>
              <Link
                href="/signup"
                className="rounded-full bg-orange px-4 py-2 text-sm font-bold text-white hover:opacity-90"
              >
                회원가입
              </Link>
            </>
          )}
        </div>

        <button
          className="flex h-10 w-10 items-center justify-center rounded-full md:hidden"
          onClick={() => setMenuOpen((v) => !v)}
          aria-label="메뉴 열기"
        >
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            {menuOpen ? (
              <path d="M6 6l12 12M6 18L18 6" strokeLinecap="round" />
            ) : (
              <path d="M3 6h18M3 12h18M3 18h18" strokeLinecap="round" />
            )}
          </svg>
        </button>
      </div>

      {menuOpen && (
        <div className="border-t border-soft-gray bg-ivory px-4 py-4 md:hidden">
          <nav className="flex flex-col gap-1">
            {NAV_LINKS.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                onClick={() => setMenuOpen(false)}
                className="rounded-lg px-3 py-2.5 text-sm font-semibold text-dark-ink hover:bg-orange-light"
              >
                {link.label}
              </Link>
            ))}
            {isAdmin && (
              <Link
                href="/admin"
                onClick={() => setMenuOpen(false)}
                className="rounded-lg px-3 py-2.5 text-sm font-semibold text-dark-ink hover:bg-orange-light"
              >
                관리자
              </Link>
            )}
            <div className="my-2 border-t border-soft-gray" />
            {loading ? null : user ? (
              <>
                <Link
                  href="/mypage"
                  onClick={() => setMenuOpen(false)}
                  className="rounded-lg px-3 py-2.5 text-sm font-semibold text-dark-ink hover:bg-orange-light"
                >
                  마이페이지 ({profile?.display_name || user.email})
                </Link>
                <button
                  onClick={handleSignOut}
                  className="rounded-lg px-3 py-2.5 text-left text-sm font-semibold text-error hover:bg-orange-light"
                >
                  로그아웃
                </button>
              </>
            ) : (
              <>
                <Link
                  href="/login"
                  onClick={() => setMenuOpen(false)}
                  className="rounded-lg px-3 py-2.5 text-sm font-semibold text-dark-ink hover:bg-orange-light"
                >
                  로그인
                </Link>
                <Link
                  href="/signup"
                  onClick={() => setMenuOpen(false)}
                  className="rounded-lg bg-orange px-3 py-2.5 text-sm font-bold text-white text-center"
                >
                  회원가입
                </Link>
              </>
            )}
          </nav>
        </div>
      )}
    </header>
  );
}
