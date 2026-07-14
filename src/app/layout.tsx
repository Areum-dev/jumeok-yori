import type { Metadata } from "next";
import { Noto_Sans_KR } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/components/AuthProvider";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";

const notoSansKr = Noto_Sans_KR({
  variable: "--font-pretendard",
  subsets: ["latin"],
  weight: ["400", "500", "700", "900"],
});

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "주먹요리 — 고민 끝, 오늘은 이거",
    template: "%s | 주먹요리",
  },
  description:
    "주는 대로 먹는 요리, 주먹요리. 거리와 가격만 정하면 주변 맛집 메뉴 중 오늘 먹을 메뉴를 무작위로 추천해드립니다.",
  keywords: ["주먹요리", "오늘 뭐 먹지", "메뉴 추천", "랜덤 메뉴", "혼밥", "맛집 추천"],
  openGraph: {
    title: "주먹요리 — 고민 끝, 오늘은 이거",
    description: "거리, 가격, 조건만 정하면 오늘의 메뉴를 골라드립니다.",
    url: siteUrl,
    siteName: "주먹요리",
    locale: "ko_KR",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko" className={`${notoSansKr.variable} h-full antialiased`}>
      <body className="flex min-h-full flex-col bg-ivory text-dark-ink">
        <AuthProvider>
          <Header />
          <main className="flex-1">{children}</main>
          <Footer />
        </AuthProvider>
      </body>
    </html>
  );
}
