"use client";

import { useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { toKoreanAuthError } from "@/lib/authErrors";
import { AuthCard, FormField, SubmitButton } from "@/components/AuthCard";

export default function ResetPasswordPage() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [sent, setSent] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    const supabase = createClient();
    const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
      redirectTo: `${window.location.origin}/auth/callback?next=/update-password`,
    });
    setLoading(false);
    if (error) {
      setError(toKoreanAuthError(error.message));
      return;
    }
    setSent(true);
  }

  if (sent) {
    return (
      <AuthCard title="메일을 확인해주세요">
        <p className="text-sm leading-relaxed text-text-gray">
          <strong className="text-dark-ink">{email}</strong> 주소로 비밀번호 재설정 링크를 보냈습니다. 메일함(스팸함
          포함)을 확인해주세요.
        </p>
        <Link href="/login" className="mt-6 block text-center text-sm font-semibold text-orange hover:underline">
          로그인 화면으로 돌아가기
        </Link>
      </AuthCard>
    );
  }

  return (
    <AuthCard title="비밀번호 재설정" subtitle="가입한 이메일로 재설정 링크를 보내드립니다">
      <form onSubmit={handleSubmit} className="space-y-4">
        <FormField
          label="이메일"
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          autoComplete="email"
        />
        {error && <p className="text-sm font-medium text-error">{error}</p>}
        <SubmitButton loading={loading}>재설정 메일 보내기</SubmitButton>
      </form>
      <Link href="/login" className="mt-6 block text-center text-sm font-semibold text-orange hover:underline">
        로그인 화면으로 돌아가기
      </Link>
    </AuthCard>
  );
}
