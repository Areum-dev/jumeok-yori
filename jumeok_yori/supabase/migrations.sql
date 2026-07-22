-- ============================================================
-- 주먹요리 - 기존 DB 마이그레이션
-- 이미 schema.sql 을 실행한 DB 에 추가 적용하세요.
-- Supabase Dashboard > SQL Editor 에서 실행.
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

-- ============================================================
-- 주먹지도 (Jumeok Map) 좌표 필드
-- ============================================================
-- owner_store_applications: 승인 전 좌표 미리 확보용
ALTER TABLE public.owner_store_applications
  ADD COLUMN IF NOT EXISTS lat FLOAT8,
  ADD COLUMN IF NOT EXISTS lng FLOAT8,
  ADD COLUMN IF NOT EXISTS geocoding_status TEXT,
  ADD COLUMN IF NOT EXISTS geocoding_error TEXT;

-- restaurants lat/lng 확인 (schema.sql 에 이미 있으면 무시됨)
ALTER TABLE public.restaurants
  ADD COLUMN IF NOT EXISTS lat FLOAT8,
  ADD COLUMN IF NOT EXISTS lng FLOAT8;

-- ============================================================
-- analytics_events (사장님 대시보드용 이벤트 로깅)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  anonymous_user_id TEXT,
  owner_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE SET NULL,
  menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE SET NULL,
  starter_menu_id UUID REFERENCES public.starter_menus(id) ON DELETE SET NULL,
  recommendation_type TEXT,
  event_type TEXT NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analytics_owner_event
  ON public.analytics_events (owner_id, event_type, created_at);

ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

-- 누구나(로그인/익명) insert 가능
DROP POLICY IF EXISTS "Anyone can insert analytics_events" ON public.analytics_events;
CREATE POLICY "Anyone can insert analytics_events" ON public.analytics_events
  FOR INSERT WITH CHECK (true);

-- 사장님은 본인(owner_id) 이벤트만, 관리자는 전체 읽기 가능
-- (개인정보 보호: 앱에서는 집계 카운트만 사용, user_id 등은 노출하지 않음)
DROP POLICY IF EXISTS "Owners can read own analytics_events" ON public.analytics_events;
CREATE POLICY "Owners can read own analytics_events" ON public.analytics_events
  FOR SELECT USING (
    auth.uid() = owner_id OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 사장님 메뉴 자동 승인 정책: 기본값을 approved 로 변경
ALTER TABLE public.menu_items
  ALTER COLUMN approval_status SET DEFAULT 'approved',
  ALTER COLUMN display_status SET DEFAULT 'approved';

-- ============================================================
-- menu-images 스토리지 버킷 (메뉴 사진 업로드용)
-- Supabase Dashboard > Storage 에서 'menu-images' public 버킷 생성하거나
-- 아래 SQL 을 실행하세요.
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
  VALUES ('menu-images', 'menu-images', true)
  ON CONFLICT (id) DO NOTHING;

-- 누구나 읽기, 로그인 사용자는 업로드 가능
DROP POLICY IF EXISTS "menu_images_public_read" ON storage.objects;
CREATE POLICY "menu_images_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'menu-images');

DROP POLICY IF EXISTS "menu_images_auth_insert" ON storage.objects;
CREATE POLICY "menu_images_auth_insert" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'menu-images' AND auth.role() = 'authenticated');

-- ============================================================
-- 2026-07-22 ~ 2026-07-23: 카카오 로그인 KOE205 대응
-- (account_email scope 완전 제거 + 닉네임/프로필 사진 저장)
--
-- 카카오 회원은 이제 email 을 절대 받지 않는다. 신규 회원 생성 시
-- 1) NEW.email 이 NULL 이어도 display_name 이 비어 보이지 않도록 기본값을 넣고
-- 2) 카카오가 제공한 닉네임/프로필 사진(raw_user_meta_data)을 profiles 에 저장한다.
-- ON CONFLICT (id) DO NOTHING 이므로 기존 회원 행은 절대 건드리지 않음
-- (신규 INSERT 트리거 로직만 교체). avatar_url 컬럼이 없으면 먼저 추가한다.
-- ============================================================
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_url TEXT;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  meta JSONB := COALESCE(NEW.raw_user_meta_data, '{}'::jsonb);
  nickname TEXT := COALESCE(
    NULLIF(meta->>'full_name', ''),
    NULLIF(meta->>'name', ''),
    NULLIF(meta->>'nickname', ''),
    split_part(NEW.email, '@', 1)
  );
  avatar TEXT := COALESCE(NULLIF(meta->>'avatar_url', ''), NULLIF(meta->>'picture', ''));
BEGIN
  INSERT INTO public.profiles (id, email, display_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(nickname, '카카오 사용자'),
    avatar
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
