"use client";

export default function GlobalError({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <html lang="ko">
      <body className="flex min-h-screen flex-col items-center justify-center bg-ivory px-4 text-center">
        <p className="text-6xl">⚠️</p>
        <h1 className="mt-4 text-2xl font-black text-dark-ink">문제가 발생했어요</h1>
        <p className="mt-2 text-sm text-text-gray">페이지를 새로고침하거나 잠시 후 다시 시도해주세요.</p>
        <button
          onClick={reset}
          className="mt-6 rounded-full bg-orange px-6 py-3 text-sm font-bold text-white hover:opacity-90"
        >
          다시 시도
        </button>
      </body>
    </html>
  );
}
