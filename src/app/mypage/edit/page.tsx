"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useAuth } from "@/components/AuthProvider";
import { AuthCard, FormField, SubmitButton } from "@/components/AuthCard";

export default function EditProfilePage() {
  const router = useRouter();
  const { user, profile, loading, refreshProfile } = useAuth();
  const [displayName, setDisplayName] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  useEffect(() => {
    if (!loading && !user) router.push("/login");
  }, [loading, user, router]);

  useEffect(() => {
    // profile 은 AuthProvider 가 비동기로 불러오므로 도착 시점에 폼 값을 동기화합니다.
    if (profile?.display_name) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setDisplayName(profile.display_name);
    }
  }, [profile]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!user) return;
    setSaving(true);
    setError(null);
    const supabase = createClient();
    const { error } = await supabase
      .from("profiles")
      .update({ display_name: displayName.trim() || null })
      .eq("id", user.id);
    setSaving(false);
    if (error) {
      setError("프로필 수정 중 오류가 발생했습니다.");
      return;
    }
    await refreshProfile();
    setDone(true);
    setTimeout(() => router.push("/mypage"), 800);
  }

  if (loading || !user) return null;

  return (
    <AuthCard title="프로필 수정">
      <form onSubmit={handleSubmit} className="space-y-4">
        <FormField label="이메일" type="email" value={user.email ?? ""} disabled readOnly />
        <FormField
          label="닉네임"
          type="text"
          value={displayName}
          onChange={(e) => setDisplayName(e.target.value)}
          placeholder="닉네임을 입력해주세요"
        />
        {error && <p className="text-sm font-medium text-error">{error}</p>}
        {done && <p className="text-sm font-medium text-success">저장되었습니다.</p>}
        <SubmitButton loading={saving}>저장</SubmitButton>
      </form>
    </AuthCard>
  );
}
