"use client";

import { createContext, useContext, useEffect, useState, useCallback } from "react";
import type { User } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/client";
import type { Profile } from "@/types/database";
import { AppConfig } from "@/lib/config";

interface AuthContextValue {
  user: User | null;
  profile: Profile | null;
  loading: boolean;
  isAdmin: boolean;
  isOwner: boolean;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue>({
  user: null,
  profile: null,
  loading: true,
  isAdmin: false,
  isOwner: false,
  refreshProfile: async () => {},
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  const loadProfile = useCallback(async (currentUser: User | null) => {
    if (!currentUser) {
      setProfile(null);
      return;
    }
    const supabase = createClient();
    const { data } = await supabase.from("profiles").select("*").eq("id", currentUser.id).maybeSingle();
    if (data) {
      setProfile(data as Profile);
    } else {
      // 트리거 미동작 대비 fallback (실제 role 은 DB 기준)
      setProfile({
        id: currentUser.id,
        email: currentUser.email ?? "",
        display_name: currentUser.email?.split("@")[0] ?? null,
        role: currentUser.email === AppConfig.adminEmail ? "admin" : "user",
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
    }
  }, []);

  const refreshProfile = useCallback(async () => {
    const supabase = createClient();
    const {
      data: { user: current },
    } = await supabase.auth.getUser();
    setUser(current);
    await loadProfile(current);
  }, [loadProfile]);

  useEffect(() => {
    const supabase = createClient();
    let mounted = true;

    supabase.auth.getUser().then(async ({ data: { user: current } }) => {
      if (!mounted) return;
      setUser(current);
      await loadProfile(current);
      setLoading(false);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (_event, session) => {
      if (!mounted) return;
      setUser(session?.user ?? null);
      await loadProfile(session?.user ?? null);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, [loadProfile]);

  const isAdmin = profile?.role === "admin";
  const isOwner = profile?.role === "owner" || isAdmin;

  return (
    <AuthContext.Provider value={{ user, profile, loading, isAdmin, isOwner, refreshProfile }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
