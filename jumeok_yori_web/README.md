# 주먹요리 웹 (jumeok_yori_web)

"주는 대로 먹는 요리" — 주먹요리의 반응형 웹 서비스입니다. **기존 Flutter 앱(`jumeok_yori`)과 완전히 동일한
Supabase 프로젝트**를 사용하며, 웹과 앱은 같은 사용자 계정·데이터베이스·Storage를 공유하는 하나의 서비스입니다.

- 실제 프로젝트 경로: `C:\Users\dlwor\Desktop\이재경\개인\사업\2.주먹요리\jumeok_yori_web`
- Flutter 앱 경로(참고): `C:\Users\dlwor\Desktop\이재경\개인\사업\2.주먹요리\jumeok_yori`

## 기술 스택

- Next.js 16 (App Router, Turbopack) + TypeScript
- Tailwind CSS v4
- Supabase (`@supabase/supabase-js`, `@supabase/ssr`) — Flutter 앱과 동일 프로젝트
- Naver Maps JS API v3 (지도), Naver Geocoding API (주소 검색)

## 앱과 웹의 연동 방식

두 클라이언트는 별개의 Supabase 프로젝트가 아니라 **동일한 프로젝트/동일한 테이블**을 사용합니다.

| 항목 | 값 |
|---|---|
| Supabase URL | `https://cggwpctgqnbetsjwhqlb.supabase.co` (Flutter `.env`와 동일) |
| Auth | 이메일 + 비밀번호 (Supabase Auth), 앱/웹 모두 동일 `auth.users` 사용 |
| 역할 구분 | `profiles.role` = `user` \| `owner` \| `admin` (양쪽 모두 동일 컬럼 사용) |
| 데이터 테이블 | `restaurants`, `menu_items`, `owner_store_applications`, `starter_menus`, `recommendation_logs`, `saved_menu_items`, `reports`, `analytics_events` — 전부 공유 |
| Storage | `menu-images`(public), `business-licenses`(private) 버킷 공유 |

웹에서 가입/등록/승인한 계정과 데이터는 앱에도 즉시 반영되고, 그 반대도 마찬가지입니다(같은 DB이므로).
RLS(Row Level Security)가 두 클라이언트 모두에게 동일하게 적용되어 권한 규칙이 일관됩니다.

## 폴더 구조

```
src/
  app/                # 라우트 (App Router)
    (auth)            # login, signup, reset-password, update-password
    recommend/         # 랜덤 메뉴 추천
    map/                # 주먹지도
    restaurants/[id]/   # 음식점 상세
    mypage/             # 마이페이지
    owner/              # 사장님 (가게/메뉴 CRUD, 대시보드)
    admin/              # 관리자 (승인/관리)
    privacy, terms, delete-account, support, ...  # 공개 법률/고객지원 페이지
    api/account/delete  # 계정 삭제 서버 API (service role)
    api/geocode         # 주소→좌표 프록시 (Naver Geocoding secret 보호)
  components/          # 재사용 UI 컴포넌트
  lib/                 # Supabase 클라이언트, 추천 로직, 유틸
  hooks/               # useLocation 등
  types/database.ts    # DB 스키마 타입 (schema.sql 기준 수기 작성)
  content/legal/        # jumeok_yori/lib/legal/*.md 원본 재사용
supabase/
  migrations_web.sql   # 웹 출시를 위한 추가(비파괴) 마이그레이션
```

## 설치 및 개발 서버 실행

```bash
npm install
npm run dev
```

http://localhost:3000 에서 확인합니다.

## 빌드

```bash
npm run build
npm start
```

## 환경변수

`.env.example` 참고 후 `.env.local` 생성. 자세한 설명은 [ENVIRONMENT_VARIABLES.md](./ENVIRONMENT_VARIABLES.md) 참고.

## Supabase 연동

기존 운영 중인 Supabase 프로젝트를 그대로 사용합니다. 새 프로젝트를 만들지 않았습니다.
DB 변경이 필요한 부분은 `supabase/migrations_web.sql` 에 추가(비파괴) 마이그레이션으로 작성했습니다.
실행 방법은 [SUPABASE_SCHEMA.md](./SUPABASE_SCHEMA.md) 참고.

## 배포

[DEPLOYMENT.md](./DEPLOYMENT.md) 참고.

## 기타 문서

- [SETUP.md](./SETUP.md) — 처음 설정하는 사람을 위한 단계별 가이드
- [SUPABASE_SCHEMA.md](./SUPABASE_SCHEMA.md) — 테이블/RLS/Storage 구조와 마이그레이션 실행 순서
- [ENVIRONMENT_VARIABLES.md](./ENVIRONMENT_VARIABLES.md) — 환경변수 전체 목록
- [GOOGLE_PLAY_RELEASE_URLS.md](./GOOGLE_PLAY_RELEASE_URLS.md) — Google Play 제출용 URL/정보
- [LEGAL_DOCUMENT_CHECKLIST.md](./LEGAL_DOCUMENT_CHECKLIST.md) — 법률 문서 점검 및 운영자가 채워야 할 항목
- [TEST_REPORT.md](./TEST_REPORT.md) — 실제 수행한 테스트 결과
