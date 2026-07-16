"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/components/AuthProvider";
import { createClient } from "@/lib/supabase/client";

export function DeleteAccountAction() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [confirmChecked, setConfirmChecked] = useState(false);
  const [typedEmail, setTypedEmail] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  if (loading) return null;

  if (!user) {
    return (
      <div className="rounded-2xl border border-soft-gray bg-white p-6">
        <p className="text-sm text-text-gray">
          웹에서 직접 삭제하려면 먼저{" "}
          <a href="/login" className="font-semibold text-orange hover:underline">
            로그인
          </a>
          이 필요합니다. 로그인이 어려우시면 아래 이메일 문의 방법을 이용해주세요.
        </p>
      </div>
    );
  }

  if (done) {
    return (
      <div className="rounded-2xl border border-success bg-green-50 p-6 text-center">
        <p className="font-bold text-dark-ink">계정 삭제가 완료되었습니다.</p>
        <p className="mt-1 text-sm text-text-gray">이용해주셔서 감사합니다.</p>
      </div>
    );
  }

  const emailMatches = typedEmail.trim().toLowerCase() === (user.email ?? "").toLowerCase();

  async function handleDelete() {
    setError(null);
    setSubmitting(true);
    try {
      const res = await fetch("/api/account/delete", { method: "POST" });
      const json = await res.json();
      if (!res.ok) {
        setError(json.error ?? "계정 삭제 중 오류가 발생했습니다.");
        setSubmitting(false);
        return;
      }
      const supabase = createClient();
      await supabase.auth.signOut();
      setDone(true);
      setTimeout(() => {
        router.push("/");
        router.refresh();
      }, 1500);
    } catch {
      setError("네트워크 오류로 삭제에 실패했습니다. 다시 시도해주세요.");
      setSubmitting(false);
    }
  }

  return (
    <div className="rounded-2xl border border-error/40 bg-white p-6">
      <p className="text-sm font-bold text-dark-ink">
        현재 로그인된 계정: <span className="text-orange">{user.email}</span>
      </p>
      <p className="mt-2 text-sm leading-relaxed text-text-gray">
        본인 확인을 위해 가입한 이메일 주소를 아래에 정확히 입력한 뒤 삭제를 진행해주세요.
        이 작업은 되돌릴 수 없습니다.
      </p>

      <label className="mt-4 block">
        <span className="mb-1.5 block text-sm font-semibold text-dark-ink">이메일 주소 확인</span>
        <input
          type="email"
          value={typedEmail}
          onChange={(e) => setTypedEmail(e.target.value)}
          placeholder={user.email ?? ""}
          className="w-full rounded-xl border border-soft-gray bg-white px-4 py-3 text-sm outline-none focus:border-orange"
        />
      </label>

      <label className="mt-4 flex items-start gap-2 text-sm text-dark-ink">
        <input
          type="checkbox"
          checked={confirmChecked}
          onChange={(e) => setConfirmChecked(e.target.checked)}
          className="mt-0.5"
        />
        위 내용을 확인했으며, 계정과 관련 데이터의 영구 삭제에 동의합니다.
      </label>

      {error && <p className="mt-3 text-sm font-medium text-error">{error}</p>}

      <button
        onClick={handleDelete}
        disabled={!confirmChecked || !emailMatches || submitting}
        className="mt-5 w-full rounded-xl bg-error py-3.5 text-sm font-bold text-white transition disabled:cursor-not-allowed disabled:opacity-40"
      >
        {submitting ? "삭제 처리 중..." : "계정 영구 삭제"}
      </button>
    </div>
  );
}
