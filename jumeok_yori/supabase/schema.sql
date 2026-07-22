-- ============================================================
-- 주먹요리 (Jumeok Yori) - Supabase Schema
-- Supabase Dashboard > SQL Editor 에서 실행하세요.
-- ============================================================

-- ── profiles ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  display_name TEXT,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user','owner','admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── restaurants ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.restaurants (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID REFERENCES public.profiles(id),
  business_number TEXT,
  name TEXT NOT NULL,
  owner_name TEXT,
  phone TEXT,
  address TEXT,
  detail_address TEXT,
  lat FLOAT8,
  lng FLOAT8,
  category TEXT,
  description TEXT,
  opening_hours TEXT,
  is_takeout_available BOOLEAN DEFAULT FALSE,
  is_delivery_available BOOLEAN DEFAULT FALSE,
  source TEXT DEFAULT 'owner_registered',
  verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending','approved','rejected','suspended')),
  display_status TEXT DEFAULT 'hidden' CHECK (display_status IN ('hidden','approved','suspended')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── owner_store_applications ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.owner_store_applications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id),
  business_number TEXT NOT NULL,
  store_name TEXT NOT NULL,
  owner_name TEXT,
  phone TEXT,
  address TEXT,
  detail_address TEXT,
  category TEXT,
  description TEXT,
  opening_hours TEXT,
  is_takeout_available BOOLEAN DEFAULT FALSE,
  is_delivery_available BOOLEAN DEFAULT FALSE,
  business_license_image_url TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','suspended')),
  admin_note TEXT,
  restaurant_id UUID REFERENCES public.restaurants(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ
);

-- ── menu_items ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.menu_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
  owner_id UUID REFERENCES public.profiles(id),
  name TEXT NOT NULL,
  description TEXT,
  price INTEGER NOT NULL CHECK (price >= 0),
  category TEXT,
  image_url TEXT,
  is_available BOOLEAN DEFAULT TRUE,
  is_takeout_available BOOLEAN DEFAULT FALSE,
  is_delivery_available BOOLEAN DEFAULT FALSE,
  is_solo_friendly BOOLEAN DEFAULT FALSE,
  is_vegan_option BOOLEAN DEFAULT FALSE,
  spicy_level INTEGER CHECK (spicy_level BETWEEN 0 AND 5),
  source TEXT DEFAULT 'owner_registered',
  approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending','approved','rejected')),
  display_status TEXT DEFAULT 'hidden' CHECK (display_status IN ('hidden','approved','suspended')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── starter_menus ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.starter_menus (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  expected_min_price INTEGER,
  expected_max_price INTEGER,
  image_url TEXT,
  is_solo_friendly BOOLEAN DEFAULT FALSE,
  is_takeout_friendly BOOLEAN DEFAULT FALSE,
  is_delivery_friendly BOOLEAN DEFAULT FALSE,
  is_vegan_option BOOLEAN DEFAULT FALSE,
  search_keyword TEXT,
  source TEXT DEFAULT 'starter_menu',
  display_status TEXT DEFAULT 'approved',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── recommendation_logs ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.recommendation_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id),
  recommendation_type TEXT NOT NULL CHECK (recommendation_type IN ('registered','starter')),
  menu_item_id UUID REFERENCES public.menu_items(id),
  starter_menu_id UUID REFERENCES public.starter_menus(id),
  restaurant_id UUID REFERENCES public.restaurants(id),
  filters_json JSONB,
  user_lat FLOAT8,
  user_lng FLOAT8,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── saved_menu_items ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.saved_menu_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.profiles(id),
  recommendation_type TEXT NOT NULL,
  menu_item_id UUID REFERENCES public.menu_items(id),
  starter_menu_id UUID REFERENCES public.starter_menus(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Helper: 현재 사용자가 admin 인지 확인
-- ============================================================
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================================
-- Trigger: 회원가입 시 profile 자동 생성
-- ============================================================
-- 2026-07-22: 카카오 로그인은 account_email scope 를 요청하지 않으므로
-- NEW.email 이 NULL 인 회원(카카오)이 정상적으로 생겨야 한다. email 이 NULL 이면
-- split_part 결과도 NULL 이 되어 display_name 이 비어 보이므로 기본값을 넣어준다.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(split_part(NEW.email, '@', 1), '카카오 사용자')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- RLS
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.owner_store_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.starter_menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_menu_items ENABLE ROW LEVEL SECURITY;

-- ── profiles ──
DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
CREATE POLICY profiles_select_own ON public.profiles
  FOR SELECT USING (id = auth.uid() OR public.is_admin());
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE USING (id = auth.uid() OR public.is_admin());
DROP POLICY IF EXISTS profiles_insert_self ON public.profiles;
CREATE POLICY profiles_insert_self ON public.profiles
  FOR INSERT WITH CHECK (id = auth.uid());

-- ── restaurants ──
DROP POLICY IF EXISTS restaurants_public_select ON public.restaurants;
CREATE POLICY restaurants_public_select ON public.restaurants
  FOR SELECT USING (display_status = 'approved' OR owner_id = auth.uid() OR public.is_admin());
DROP POLICY IF EXISTS restaurants_owner_all ON public.restaurants;
CREATE POLICY restaurants_owner_all ON public.restaurants
  FOR ALL USING (owner_id = auth.uid() OR public.is_admin())
  WITH CHECK (owner_id = auth.uid() OR public.is_admin());

-- ── menu_items ──
DROP POLICY IF EXISTS menu_items_public_select ON public.menu_items;
CREATE POLICY menu_items_public_select ON public.menu_items
  FOR SELECT USING (
    (approval_status = 'approved' AND display_status = 'approved')
    OR owner_id = auth.uid()
    OR public.is_admin()
  );
DROP POLICY IF EXISTS menu_items_owner_all ON public.menu_items;
CREATE POLICY menu_items_owner_all ON public.menu_items
  FOR ALL USING (owner_id = auth.uid() OR public.is_admin())
  WITH CHECK (owner_id = auth.uid() OR public.is_admin());

-- ── starter_menus ──
DROP POLICY IF EXISTS starter_menus_public_select ON public.starter_menus;
CREATE POLICY starter_menus_public_select ON public.starter_menus
  FOR SELECT USING (display_status = 'approved' OR public.is_admin());
DROP POLICY IF EXISTS starter_menus_admin_all ON public.starter_menus;
CREATE POLICY starter_menus_admin_all ON public.starter_menus
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ── owner_store_applications ──
DROP POLICY IF EXISTS osa_insert_own ON public.owner_store_applications;
CREATE POLICY osa_insert_own ON public.owner_store_applications
  FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS osa_select_own ON public.owner_store_applications;
CREATE POLICY osa_select_own ON public.owner_store_applications
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
DROP POLICY IF EXISTS osa_admin_update ON public.owner_store_applications;
CREATE POLICY osa_admin_update ON public.owner_store_applications
  FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ── recommendation_logs ──
DROP POLICY IF EXISTS reclog_insert ON public.recommendation_logs;
CREATE POLICY reclog_insert ON public.recommendation_logs
  FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS reclog_select_own ON public.recommendation_logs;
CREATE POLICY reclog_select_own ON public.recommendation_logs
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

-- ── saved_menu_items ──
DROP POLICY IF EXISTS saved_all_own ON public.saved_menu_items;
CREATE POLICY saved_all_own ON public.saved_menu_items
  FOR ALL USING (user_id = auth.uid() OR public.is_admin())
  WITH CHECK (user_id = auth.uid() OR public.is_admin());

-- ============================================================
-- 추가: 익명 추천 기록 / 신고 (migrations.sql 와 동일 내용)
-- ============================================================

-- recommendation_logs 에 anonymous_user_id 추가
ALTER TABLE public.recommendation_logs
  ADD COLUMN IF NOT EXISTS anonymous_user_id TEXT;

-- reports 테이블
CREATE TABLE IF NOT EXISTS public.reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id),
  anonymous_user_id TEXT,
  recommendation_type TEXT,
  menu_item_id UUID REFERENCES public.menu_items(id),
  starter_menu_id UUID REFERENCES public.starter_menus(id),
  restaurant_id UUID REFERENCES public.restaurants(id),
  reason TEXT NOT NULL,
  detail TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','reviewed','resolved')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS reports_insert ON public.reports;
CREATE POLICY reports_insert ON public.reports
  FOR INSERT WITH CHECK (TRUE);
DROP POLICY IF EXISTS reports_admin_select ON public.reports;
CREATE POLICY reports_admin_select ON public.reports
  FOR SELECT USING (public.is_admin());
DROP POLICY IF EXISTS reports_admin_update ON public.reports;
CREATE POLICY reports_admin_update ON public.reports
  FOR UPDATE USING (public.is_admin());

-- recommendation_logs RLS 갱신 (익명 insert 허용)
DROP POLICY IF EXISTS reclog_insert ON public.recommendation_logs;
CREATE POLICY reclog_insert ON public.recommendation_logs
  FOR INSERT WITH CHECK (TRUE);
