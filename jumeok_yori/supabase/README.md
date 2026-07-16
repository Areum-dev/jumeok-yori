# 주먹요리 Supabase 설정 가이드

## 1. SQL 실행 순서
Supabase Dashboard → SQL Editor에서 아래 순서대로 실행:

1. `supabase/schema.sql` — 테이블, RLS, 트리거 생성 (최초 1회)
2. `supabase/seed.sql` — starter_menus 기본 데이터 (최초 1회)
3. `supabase/storage.sql` — 스토리지 버킷 생성 (최초 1회)
4. `supabase/migrations.sql` — 기존 DB 업데이트 시 (schema.sql 이후 변경사항)
5. `supabase/migrations_web.sql` — 웹(jumeok-yori-web) 출시를 위한 추가 마이그레이션
   (restaurants.image_url 컬럼, analytics_events 테이블, storage 버킷, starter_menus 추가분).
   2026-07-14 기준 REST API 점검 결과 이 항목들이 아직 운영 DB에 적용되지 않아 새로 작성했습니다.
   기존 데이터를 삭제/초기화하지 않는 추가(ADD)/생성(CREATE IF NOT EXISTS) 위주입니다.

## 2. Auth 설정
- Dashboard → Authentication → Providers → Email
- **Confirm email**: ON (회원가입 시 이메일 인증 메일 발송)
- Dashboard → Authentication → Settings
- **Site URL**: 배포 URL (예: https://your-app.vercel.app)
- **Redirect URLs**: 배포 URL 추가
- 로그인 방식은 **이메일 + 비밀번호** 만 사용합니다 (OTP / 매직링크 미사용).

### SMTP 설정 (이메일 발송용)
무료 플랜 기본 한도: 하루 3건 → 실서비스에서는 SMTP 설정 필요

추천: Resend (resend.com)
- Host: smtp.resend.com
- Port: 465
- User: resend
- Password: Resend API Key
- Sender: onboarding@resend.dev (또는 본인 도메인)

## 3. 관리자 계정 설정
1. Dashboard → Authentication → Users → Add user
2. 이메일: 1vpsrnls@gmail.com
3. 비밀번호: 직접 설정 (절대 코드/README/GitHub에 저장 금지)
4. Dashboard → Table Editor → profiles
5. 해당 유저의 role 값을 `admin`으로 변경

> **주의**: 관리자 비밀번호는 코드, README, seed.sql, GitHub에 절대 기록하지 마세요.

## 4. Storage 버킷
`storage.sql` 실행으로 자동 생성됩니다.
- `menu-images`: public (메뉴 사진)
- `business-licenses`: private (사업자등록증)

수동 생성 시: Dashboard → Storage → New bucket

## 5. 환경 변수 설정
프로젝트 루트에 `.env` 파일 생성 (`.gitignore`에 포함됨):
```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key
USE_SUPABASE=true
```
값 확인: Dashboard → Settings → API
`.env.example`을 참고해 `.env`를 생성하세요.

## 6. 네이버 Geocoding API 설정 (주먹지도)
- Naver Cloud Platform (https://www.ncloud.com) 가입
- Application 등록 → "Maps" → "Geocoding" 서비스 활성화
- Client ID와 Client Secret 발급
- `.env` 파일에 입력:
  ```
  NAVER_MAP_CLIENT_ID=발급받은_Client_ID
  NAVER_MAP_CLIENT_SECRET=발급받은_Client_Secret
  ```
- API 키 없이도 앱 실행 가능 (지도 fallback 모드)
- 관리자 페이지에서 수동으로 lat/lng 입력 가능
- lat/lng가 없는 가게는 주먹지도에 표시되지 않음
- 승인된 가게만 주먹지도에 표시됨
- 좌표 필드 추가는 `migrations.sql` 실행으로 반영됩니다.

## 7. Android Release Build
```bash
flutter clean
flutter pub get
flutter analyze
flutter build appbundle --release
```
빌드 전 서명 키스토어 설정 필요 → RELEASE_CHECKLIST.md 참고
