"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { toKoreanAuthError } from "@/lib/authErrors";
import { AuthCard, FormField, SubmitButton } from "@/components/AuthCard";

export default function UpdatePasswordPage() {
  const router = useRouter();
  const [password, setPassword] = useState("");
  const [passwordConfirm, setPasswordConfirm] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    if (password.length < 6) {
      setError("비밀번호는 6자 이상이어야 합니다.");
      return;
    }
    if (password !== passwordConfirm) {
      setError("비밀번호가 일치하지 않습니다.");
      return;
    }

    setLoading(true);
    const supabase = createClient();
    const { error } = await supabase.auth.updateUser({ password });
    setLoading(false);

    if (error) {
      setError(toKoreanAuthError(error.message));
      return;
    }
    setDone(true);
    setTimeout(() => router.push("/mypage"), 1200);
  }

  if (done) {
    return (
      <AuthCard title="비밀번호가 변경되었습니다">
        <p className="text-sm text-text-gray">잠시 후 마이페이지로 이동합니다.</p>
      </AuthCard>
    );
  }

  return (
    <AuthCard title="새 비밀번호 설정" subtitle="이메일 링크를 통해 인증되었습니다">
      <form onSubmit={handleSubmit} className="space-y-4">
        <FormField
          label="새 비밀번호 (6자 이상)"
          type="password"
          required
          minLength={6}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          autoComplete="new-password"
        />
        <FormField
          label="새 비밀번호 확인"
          type="password"
          required
          value={passwordConfirm}
          onChange={(e) => setPasswordConfirm(e.target.value)}
          autoComplete="new-password"
        />
        {error && <p className="text-sm font-medium text-error">{error}</p>}
        <SubmitButton loading={loading}>비밀번호 변경</SubmitButton>
      </form>
    </AuthCard>
  );
}
