"use client";

import { useState, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { toKoreanAuthError } from "@/lib/authErrors";
import { AuthCard, FormField, SubmitButton } from "@/components/AuthCard";

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(searchParams.get("error"));

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });
    setLoading(false);
    if (error) {
      setError(toKoreanAuthError(error.message));
      return;
    }
    router.push("/mypage");
    router.refresh();
  }

  return (
    <AuthCard title="로그인" subtitle="주먹요리 계정으로 로그인하세요">
      <form onSubmit={handleSubmit} className="space-y-4">
        <FormField
          label="이메일"
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          autoComplete="email"
        />
        <FormField
          label="비밀번호"
          type="password"
          required
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          autoComplete="current-password"
        />
        {error && <p className="text-sm font-medium text-error">{error}</p>}
        <SubmitButton loading={loading}>로그인</SubmitButton>
      </form>
      <div className="mt-6 flex justify-between text-sm">
        <Link href="/signup" className="font-semibold text-orange hover:underline">
          회원가입
        </Link>
        <Link href="/reset-password" className="text-text-gray hover:underline">
          비밀번호를 잊으셨나요?
        </Link>
      </div>
    </AuthCard>
  );
}

export default function LoginPage() {
  return (
    <Suspense>
      <LoginForm />
    </Suspense>
  );
}
