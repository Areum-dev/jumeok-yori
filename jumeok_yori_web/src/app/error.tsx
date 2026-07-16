"use client";

import { useEffect } from "react";

export default function ErrorPage({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // 내부 키/스택은 노출하지 않고 콘솔에만 기록합니다.
    console.error(error);
  }, [error]);

  return (
    <div className="mx-auto flex min-h-[60vh] max-w-lg flex-col items-center justify-center px-4 text-center">
      <p className="text-6xl">⚠️</p>
      <h1 className="mt-4 text-2xl font-black text-dark-ink">일시적인 오류가 발생했어요</h1>
      <p className="mt-2 text-sm text-text-gray">잠시 후 다시 시도해주세요. 문제가 계속되면 고객지원에 문의해주세요.</p>
      <div className="mt-6 flex gap-3">
        <button
          onClick={reset}
          className="rounded-full bg-orange px-6 py-3 text-sm font-bold text-white hover:opacity-90"
        >
          다시 시도
        </button>
        <a
          href="/support"
          className="rounded-full border border-soft-gray px-6 py-3 text-sm font-bold text-dark-ink hover:border-orange"
        >
          고객지원
        </a>
      </div>
    </div>
  );
}
