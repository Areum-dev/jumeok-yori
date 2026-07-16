-- ============================================================
-- 주먹요리 웹(jumeok-yori-web) 출시를 위한 추가 마이그레이션
-- 작성일: 2026-07-14
--
-- 이 파일은 schema.sql + migrations.sql 이 이미 적용된 운영 DB를 대상으로 합니다.
-- 모두 추가(ADD)/생성(CREATE IF NOT EXISTS) 위주이며 기존 데이터를 삭제하거나
-- 초기화하지 않습니다. Supabase Dashboard > SQL Editor 에서 그대로 실행하세요.
--
-- 실행 전 확인된 사항 (2026-07-14 기준, REST API로 점검):
--  - restaurants 테이블에 image_url 컬럼이 없음 (앱 모델은 참조하고 있었음) → 아래에서 추가
--  - analytics_events 테이블이 아직 생성되지 않음 (migrations.sql 의 해당 부분 미적용) → 아래에서 재적용
--  - storage 버킷 menu-images / business-licenses 가 아직 생성되지 않음 → 아래에서 생성
--  - starter_menus 는 seed.sql 의 23개만 있고 Flutter 앱 mock_data_repository.dart 의
--    50개 기본 음식 목록 중 나머지 27개가 비어있음 → 아래에서 이름 중복 없이 추가
--  - reports, recommendation_logs.anonymous_user_id, owner_store_applications.lat/lng 는
--    이미 적용되어 있어 이 파일에서 다시 다루지 않습니다.
-- ============================================================

-- ── 1. restaurants.image_url (사장님 대표 이미지 업로드용) ──
ALTER TABLE public.restaurants
  ADD COLUMN IF NOT EXISTS image_url TEXT;

-- ── 2. analytics_events (사장님 대시보드 통계) ──
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

DROP POLICY IF EXISTS "Anyone can insert analytics_events" ON public.analytics_events;
CREATE POLICY "Anyone can insert analytics_events" ON public.analytics_events
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Owners can read own analytics_events" ON public.analytics_events;
CREATE POLICY "Owners can read own analytics_events" ON public.analytics_events
  FOR SELECT USING (
    auth.uid() = owner_id OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 사장님 메뉴 자동 승인 정책 재확인 (이미 적용되어 있다면 동일 값으로 재설정될 뿐 무해함)
ALTER TABLE public.menu_items
  ALTER COLUMN approval_status SET DEFAULT 'approved',
  ALTER COLUMN display_status SET DEFAULT 'approved';

-- ── 3. Storage 버킷 (menu-images: public, business-licenses: private) ──
INSERT INTO storage.buckets (id, name, public)
  VALUES ('menu-images', 'menu-images', true)
  ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
  VALUES ('business-licenses', 'business-licenses', false)
  ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "menu_images_public_read" ON storage.objects;
CREATE POLICY "menu_images_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'menu-images');

DROP POLICY IF EXISTS "menu_images_auth_insert" ON storage.objects;
CREATE POLICY "menu_images_auth_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'menu-images');

DROP POLICY IF EXISTS "menu_images_owner_update" ON storage.objects;
CREATE POLICY "menu_images_owner_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'menu-images' AND owner = auth.uid());

DROP POLICY IF EXISTS "menu_images_owner_delete" ON storage.objects;
CREATE POLICY "menu_images_owner_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'menu-images' AND owner = auth.uid());

DROP POLICY IF EXISTS "biz_license_read" ON storage.objects;
CREATE POLICY "biz_license_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'business-licenses'
    AND (owner = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
  );

DROP POLICY IF EXISTS "biz_license_write" ON storage.objects;
CREATE POLICY "biz_license_write" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'business-licenses' AND owner = auth.uid());

-- ── 4. starter_menus: Flutter 앱 mock_data_repository.dart 의 50개 기본 음식 중
--       seed.sql 에 없던 나머지를 이름 중복 없이 추가 (허위 가게명/주소 없음) ──
INSERT INTO public.starter_menus
  (name, description, category, expected_min_price, expected_max_price,
   is_solo_friendly, is_takeout_friendly, is_delivery_friendly, is_vegan_option, search_keyword)
SELECT v.name, v.description, v.category, v.expected_min_price, v.expected_max_price,
       v.is_solo_friendly, v.is_takeout_friendly, v.is_delivery_friendly, v.is_vegan_option, v.search_keyword
FROM (VALUES
  ('김치찌개', '진한 김치 국물에 돼지고기와 두부', '한식', 7000, 11000, true, false, true, false, '김치찌개'),
  ('순댓국', '구수한 순대국 한 그릇', '한식', 7000, 10000, true, false, false, false, '순댓국'),
  ('설렁탕', '오래 끓인 맑은 사골 육수', '한식', 8000, 12000, true, false, false, false, '설렁탕'),
  ('갈비탕', '진한 소갈비 국물', '한식', 10000, 15000, true, false, false, false, '갈비탕'),
  ('부대찌개', '햄·소시지·라면이 들어간 얼큰 찌개', '한식', 9000, 13000, true, false, true, false, '부대찌개'),
  ('제육볶음', '매콤달콤한 돼지고기 볶음', '한식', 8000, 12000, true, true, true, false, '제육볶음'),
  ('불고기', '달콤한 간장 양념 소불고기', '한식', 10000, 16000, true, true, true, false, '불고기'),
  ('삼겹살', '두툼한 삼겹살 구이', '한식', 12000, 20000, false, false, false, false, '삼겹살'),
  ('닭갈비', '매콤한 춘천식 닭갈비', '한식', 10000, 16000, true, true, true, false, '닭갈비'),
  ('찜닭', '달콤짭짤한 안동식 찜닭', '한식', 10000, 18000, false, false, true, false, '찜닭'),
  ('닭강정', '바삭하고 달콤한 닭강정', '한식', 8000, 14000, true, true, true, false, '닭강정'),
  ('치킨', '바삭한 프라이드 치킨', '패스트푸드', 10000, 20000, false, true, true, false, '치킨'),
  ('족발', '쫄깃한 족발 보쌈 세트', '한식', 15000, 25000, false, true, true, false, '족발'),
  ('보쌈', '수육과 김치를 함께 즐기는 보쌈', '한식', 12000, 22000, false, true, true, false, '보쌈'),
  ('곱창볶음', '매콤하게 볶은 소곱창', '한식', 12000, 18000, true, false, false, false, '곱창'),
  ('감자탕', '칼칼한 돼지 등뼈 감자탕', '한식', 8000, 13000, true, false, true, false, '감자탕'),
  ('라면', '얼큰하고 뜨끈한 라면 한 그릇', '분식', 4000, 7000, true, true, false, false, '라면'),
  ('순대볶음', '야채와 함께 볶은 매콤한 순대', '분식', 7000, 11000, true, true, true, false, '순대'),
  ('오므라이스', '계란 오믈렛에 케첩 볶음밥', '양식', 8000, 13000, true, true, true, false, '오므라이스'),
  ('라멘', '진한 국물의 일본식 라멘', '일식', 10000, 16000, true, false, false, false, '라멘'),
  ('규동', '달콤한 소고기 덮밥', '일식', 8000, 13000, true, true, true, false, '규동'),
  ('탕수육', '바삭한 탕수육과 새콤달콤한 소스', '중식', 10000, 18000, false, true, true, false, '탕수육'),
  ('볶음밥', '고소한 계란 볶음밥', '중식', 7000, 11000, true, true, true, false, '볶음밥'),
  ('피자', '쫄깃한 도우의 화덕 피자', '패스트푸드', 10000, 20000, false, true, true, false, '피자'),
  ('샌드위치', '신선한 재료의 수제 샌드위치', '카페/디저트', 6000, 12000, true, true, true, false, '샌드위치'),
  ('스테이크', '부드러운 등심 스테이크', '양식', 18000, 35000, true, false, false, false, '스테이크'),
  ('팟타이', '태국식 볶음 쌀국수', '양식', 10000, 15000, true, true, true, false, '팟타이'),
  ('카레라이스', '진한 일본식 카레와 밥', '일식', 8000, 13000, true, true, true, true, '카레')
) AS v(name, description, category, expected_min_price, expected_max_price,
       is_solo_friendly, is_takeout_friendly, is_delivery_friendly, is_vegan_option, search_keyword)
WHERE NOT EXISTS (
  SELECT 1 FROM public.starter_menus sm WHERE sm.name = v.name
);
