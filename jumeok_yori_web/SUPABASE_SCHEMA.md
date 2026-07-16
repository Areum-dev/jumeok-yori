# Supabase 스키마 및 마이그레이션

이 프로젝트는 **기존에 운영 중인 Supabase 프로젝트를 그대로 사용**합니다 (`cggwpctgqnbetsjwhqlb.supabase.co`).
새 프로젝트를 만들지 않았고, 기존 테이블/데이터를 삭제하거나 초기화하지 않았습니다.

## 실제 테이블 (schema.sql 기준, REST API로 실사용 여부 확인함)

| 테이블 | 용도 | 비고 |
|---|---|---|
| `profiles` | 사용자 프로필/역할 | `role`: `user` \| `owner` \| `admin`, `handle_new_user` 트리거로 가입 시 자동 생성 |
| `restaurants` | 승인된 음식점 | `verification_status`, `display_status`, `lat/lng`, **`image_url`(이번에 추가)** |
| `owner_store_applications` | 사장님 가게 등록 신청 | 승인 시 `restaurants` row 생성/갱신 |
| `menu_items` | 메뉴 | `approval_status`, `display_status` |
| `starter_menus` | 기본(스타터) 음식 목록 | 등록 메뉴 부족 시 추천 폴백용, 실제 가게 아님 |
| `recommendation_logs` | 추천 기록 | `user_id` 또는 `anonymous_user_id` |
| `saved_menu_items` | 저장(찜) | 로그인 사용자 전용, RLS로 본인 것만 접근 |
| `reports` | 신고 | 익명 insert 허용, 관리자만 조회/처리 |
| `analytics_events` | 사장님 대시보드 통계 | **운영 DB에 미생성 상태 확인됨 → migrations_web.sql 로 생성 필요** |

## 실행 전 REST API로 직접 확인한 사실 (2026-07-14)

anon key로 실제 운영 DB에 쿼리하여 다음을 확인했습니다 (SQL을 실행한 것이 아니라 조회만 했습니다):

- `restaurants` 테이블에 실제 가게 데이터 1건 존재 (`부팔라 리스토란테 피제리아`) — **건드리지 않음**
- `menu_items` 는 현재 0건
- `starter_menus` 는 seed.sql 의 23건만 존재 (Flutter mock 목록은 50개)
- `reports`, `recommendation_logs.anonymous_user_id`, `owner_store_applications.lat/lng` 컬럼은
  이미 `migrations.sql` 이 적용되어 존재함
- **`analytics_events` 테이블은 존재하지 않음** (`migrations.sql`에 정의는 있으나 미실행 상태)
- **Storage 버킷 `menu-images`, `business-licenses` 는 아직 생성되지 않음** (`storage.sql` 미실행 상태)
- **`restaurants.image_url` 컬럼이 없음** — Flutter 앱의 `Restaurant` 모델은 이 필드를 참조하지만
  실제 DB에는 없어서, 사장님 대표 이미지 업로드 기능은 지금까지 동작할 수 없는 상태였습니다.

## 실행해야 하는 마이그레이션

**`jumeok_yori/supabase/migrations_web.sql`** (웹 프로젝트에도 동일 파일을 `supabase/migrations_web.sql` 로 복사해 두었습니다)

이 SQL을 **Supabase Dashboard → SQL Editor** 에서 실행해야 아래 기능이 정상 동작합니다.

| 실행 안 하면 | 실행하면 |
|---|---|
| 사장님 가게 대표 이미지가 저장되지 않음 | `restaurants.image_url` 저장 가능 |
| 사장님 대시보드 통계가 전부 0으로만 표시 (오류는 아님, `try/catch`로 방어) | 추천/조회 이벤트가 실제로 기록·집계됨 |
| 메뉴/가게/사업자등록증 이미지 업로드 시 오류 발생 | Storage 업로드 정상 동작 |
| 기본 추천 음식이 23종만 존재 | Flutter mock과 동일한 50종으로 확장 |

DROP, TRUNCATE, 전체 DELETE는 포함되어 있지 않으며, 모두 `ADD COLUMN IF NOT EXISTS`,
`CREATE TABLE IF NOT EXISTS`, `INSERT ... WHERE NOT EXISTS` 형태의 **추가 전용** 마이그레이션입니다.

### 실행 순서 (신규 DB라면 전체, 기존 운영 DB라면 5번만)

1. `supabase/schema.sql`
2. `supabase/seed.sql`
3. `supabase/storage.sql`
4. `supabase/migrations.sql`
5. **`supabase/migrations_web.sql`** ← 이번에 새로 작성, 아직 미실행

## RLS 정책 (변경하지 않음, 기존 그대로 사용)

모든 테이블에 RLS가 이미 적용되어 있으며 이번 작업에서 정책을 변경하지 않았습니다
(`analytics_events`, storage 버킷 정책은 `migrations.sql`/`storage.sql`에 이미 정의된 내용을
그대로 재적용하는 것뿐입니다). 핵심 규칙:

- 일반 사용자: 승인된(`display_status='approved'`) 가게/메뉴만 조회 가능, 본인 프로필/추천기록/찜만 조회·수정 가능
- 사장님: 본인 소유(`owner_id = auth.uid()`) 가게/메뉴만 CRUD 가능
- 관리자: `profiles.role = 'admin'` 인 경우 `is_admin()` 함수를 통해 전체 접근 가능
- 관리자 판별은 클라이언트 화면 숨김이 아니라 **DB RLS의 `is_admin()` 함수**가 최종 방어선입니다
  (`src/lib/requireAdmin.ts` 는 추가로 서버 컴포넌트 단계에서도 재확인합니다)

## Storage 버킷

| 버킷 | 공개 여부 | 정책 |
|---|---|---|
| `menu-images` | public | 누구나 읽기, 로그인 사용자 업로드, 본인 파일만 수정/삭제 |
| `business-licenses` | private | 본인 또는 관리자만 읽기, 로그인 사용자 업로드 |

파일 경로는 `${userId}/${uuid}.${ext}` 형태로 저장해 다른 사용자 파일과 충돌하지 않습니다.
업로드 전 확장자(jpg/png/webp/gif)와 크기(5MB 이하)를 클라이언트에서 검증합니다
(`src/lib/uploadImage.ts`).

## 관리자 계정

기존 문서(`jumeok_yori/supabase/README.md`)에 안내된 대로, Supabase Dashboard에서 직접
`profiles.role` 을 `admin` 으로 설정해야 합니다. 이 저장소에는 관리자 비밀번호를 저장하지 않았습니다.
