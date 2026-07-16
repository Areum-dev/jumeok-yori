import Link from "next/link";
import Image from "next/image";
import { AppConfig } from "@/lib/config";

const LEGAL_LINKS = [
  { href: "/terms", label: "이용약관" },
  { href: "/privacy", label: "개인정보처리방침" },
  { href: "/delete-account", label: "계정 삭제" },
  { href: "/support", label: "고객지원" },
];

export function Footer() {
  return (
    <footer className="border-t border-soft-gray bg-white">
      <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
        <div className="flex flex-col gap-6 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <div className="flex items-center gap-2 text-base font-extrabold text-dark-ink">
              <Image src="/logo-square.png" alt="주먹요리" width={28} height={28} className="h-7 w-7 rounded-full object-cover" />
              주먹요리
            </div>
            <p className="mt-2 max-w-sm text-sm leading-relaxed text-text-gray">
              &ldquo;주는 대로 먹는 요리&rdquo;. 거리, 가격, 조건만 정하면 오늘 먹을 메뉴를 대신 골라드려요.
            </p>
          </div>

          <nav className="flex flex-wrap gap-x-6 gap-y-2">
            {LEGAL_LINKS.map((l) => (
              <Link key={l.href} href={l.href} className="text-sm font-medium text-text-gray hover:text-orange">
                {l.label}
              </Link>
            ))}
          </nav>
        </div>

        <div className="mt-8 border-t border-soft-gray pt-6 text-xs leading-relaxed text-mid-gray">
          <p>사업자 등록 정보: 준비 중 (운영자가 실제 정보로 업데이트 예정)</p>
          <p>문의: {AppConfig.supportEmail}</p>
          <p className="mt-2">© {new Date().getFullYear()} 주먹요리. All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
}
