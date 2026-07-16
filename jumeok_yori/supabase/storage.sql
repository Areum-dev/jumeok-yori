-- ============================================================
-- 주먹요리 Storage 설정
-- Supabase Dashboard > Storage 에서 버킷을 만든 뒤,
-- 아래 정책을 SQL Editor 에서 실행하세요.
-- ============================================================

-- 버킷 생성 (Dashboard > Storage > New bucket 으로도 가능)
--  - menu-images        : public read,  authenticated write
--  - business-licenses  : private,      owner & admin read

INSERT INTO storage.buckets (id, name, public)
VALUES ('menu-images', 'menu-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('business-licenses', 'business-licenses', false)
ON CONFLICT (id) DO NOTHING;

-- ── menu-images : 누구나 읽기, 로그인 사용자만 업로드 ──
DROP POLICY IF EXISTS menu_images_read ON storage.objects;
CREATE POLICY menu_images_read ON storage.objects
  FOR SELECT USING (bucket_id = 'menu-images');

DROP POLICY IF EXISTS menu_images_write ON storage.objects;
CREATE POLICY menu_images_write ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'menu-images');

DROP POLICY IF EXISTS menu_images_update ON storage.objects;
CREATE POLICY menu_images_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'menu-images' AND owner = auth.uid());

-- ── business-licenses : 본인 + 관리자만 읽기, 본인만 업로드 ──
DROP POLICY IF EXISTS biz_license_read ON storage.objects;
CREATE POLICY biz_license_read ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'business-licenses'
         AND (owner = auth.uid() OR public.is_admin()));

DROP POLICY IF EXISTS biz_license_write ON storage.objects;
CREATE POLICY biz_license_write ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'business-licenses' AND owner = auth.uid());
