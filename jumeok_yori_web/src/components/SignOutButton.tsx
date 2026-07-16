"use client";

import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export function SignOutButton() {
  const router = useRouter();

  async function handleSignOut() {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  }

  return (
    <button
      onClick={handleSignOut}
      className="w-full rounded-2xl border border-soft-gray bg-white py-3.5 text-sm font-bold text-dark-ink transition hover:border-orange hover:text-orange"
    >
      로그아웃
    </button>
  );
}
