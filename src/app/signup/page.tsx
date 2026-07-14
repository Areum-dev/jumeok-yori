"use client";

import { useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { toKoreanAuthError } from "@/lib/authErrors";
import { AuthCard, FormField, SubmitButton } from "@/components/AuthCard";

export default function SignupPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [passwordConfirm, setPasswordConfirm] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [agreeRequired, setAgreeRequired] = useState(false);
  const [agreeMarketing, setAgreeMarketing] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [emailSent, setEmailSent] = useState(false);

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
    if (!agreeRequired) {
      setError("필수 약관에 모두 동의해주세요.");
      return;
    }

    setLoading(true);
    const supabase = createClient();
    const { data, error } = await supabase.auth.signUp({
      email: email.trim(),
      password,
      options: {
        data: {
          display_name: displayName || undefined,
          marketing_consent: agreeMarketing,
        },
        emailRedirectTo: `${window.location.origin}/auth/callback`,
      },
    });
    setLoading(false);

    if (error) {
      setError(toKoreanAuthError(error.message));
      return;
    }

    if (data.session) {
      window.location.href = "/mypage";
      return;
    }
    setEmailSent(true);
  }

  if (emailSent) {
    return (
      <AuthCard title="이메일을 확인해주세요">
        <p className="text-sm leading-relaxed text-text-gray">
          <strong className="text-dark-ink">{email}</strong> 주소로 인증 메일을 보냈습니다. 메일함(스팸함 포함)에서
          인증 링크를 눌러 가입을 완료해주세요.
        </p>
        <Link href="/login" className="mt-6 block text-center text-sm font-semibold text-orange hover:underline">
          로그인 화면으로 돌아가기
        </Link>
      </AuthCard>
    );
  }

  return (
    <AuthCard title="회원가입" subtitle="주먹요리와 함께 오늘의 메뉴를 골라보세요">
      <form onSubmit={handleSubmit} className="space-y-4">
        <FormField
          label="닉네임 (선택)"
          type="text"
          value={displayName}
          onChange={(e) => setDisplayName(e.target.value)}
          placeholder="미입력 시 이메일 앞부분 사용"
        />
        <FormField
          label="이메일"
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          autoComplete="email"
        />
        <FormField
          label="비밀번호 (6자 이상)"
          type="password"
          required
          minLength={6}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          autoComplete="new-password"
        />
        <FormField
          label="비밀번호 확인"
          type="password"
          required
          value={passwordConfirm}
          onChange={(e) => setPasswordConfirm(e.target.value)}
          autoComplete="new-password"
        />

        <div className="space-y-2 rounded-xl border border-soft-gray bg-ivory p-4">
          <label className="flex items-start gap-2 text-sm text-dark-ink">
            <input
              type="checkbox"
              checked={agreeRequired}
              onChange={(e) => setAgreeRequired(e.target.checked)}
              className="mt-0.5"
              required
            />
            <span>
              (필수) 만 14세 이상이며,{" "}
              <Link href="/terms" target="_blank" className="font-semibold text-orange hover:underline">
                이용약관
              </Link>
              ,{" "}
              <Link href="/privacy" target="_blank" className="font-semibold text-orange hover:underline">
                개인정보처리방침
              </Link>
              ,{" "}
              <Link href="/location-policy" target="_blank" className="font-semibold text-orange hover:underline">
                위치정보 이용약관
              </Link>
              에 모두 동의합니다.
            </span>
          </label>
          <label className="flex items-start gap-2 text-sm text-dark-ink">
            <input
              type="checkbox"
              checked={agreeMarketing}
              onChange={(e) => setAgreeMarketing(e.target.checked)}
              className="mt-0.5"
            />
            <span>
              (선택){" "}
              <Link href="/marketing-consent" target="_blank" className="font-semibold text-orange hover:underline">
                마케팅 정보 수신
              </Link>
              에 동의합니다.
            </span>
          </label>
        </div>

        {error && <p className="text-sm font-medium text-error">{error}</p>}
        <SubmitButton loading={loading}>회원가입</SubmitButton>
      </form>
      <p className="mt-6 text-center text-sm text-text-gray">
        이미 계정이 있으신가요?{" "}
        <Link href="/login" className="font-semibold text-orange hover:underline">
          로그인
        </Link>
      </p>
    </AuthCard>
  );
}
