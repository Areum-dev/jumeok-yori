# 테스트 리포트

작성일: 2026-07-14. "완료"라고 표시한 항목은 실제로 실행/확인한 것만입니다.
브라우저 자동화 도구(Chrome 확장 등)가 이 세션에 연결되어 있지 않아, 클릭 기반 E2E 테스트는
**직접 수행하지 못했습니다.** 아래에 검증한 것과 검증하지 못한 것을 정확히 구분해 기록합니다.

## ✅ 실제로 실행하고 확인한 것

### 빌드/정적 검증
- `npm run build` — **성공** (TypeScript 오류 0건, 34개 라우트 모두 정상 빌드)
- `npx eslint .` — **성공** (오류 0건, 경고 0건)
- 개발 서버(`npm run dev`) 정상 기동 확인

### 실제 운영 Supabase 연결 확인 (curl로 직접 조회)
- 웹 서버가 실제 운영 DB(`cggwpctgqnbetsjwhqlb.supabase.co`)에서 데이터를 가져오는지 확인:
  `/restaurants/d1681f35-c1ca-4f48-be69-46e234fa8f68` 접속 시 실제 등록된 가게
  **"부팔라 리스토란테 피제리아"** 의 이름, 주소, 전화번호, 영업시간, 소개, 포장/배달 가능 여부가
  정확히 렌더링됨을 확인했습니다. → **Flutter 앱과 동일한 데이터베이스를 사용한다는 것을 실증**
- REST API(anon key)로 실제 테이블 상태를 조회해 스키마 문서를 작성함 (아래 SUPABASE_SCHEMA.md 참고)
- Naver Geocoding API를 서버 라우트를 통해 실제 호출 → 처음엔 401 "구독 필요" 오류 발생.
  콘솔 서비스/결제 설정을 모두 확인한 뒤 두 도메인을 직접 비교 테스트해 **원인이 Naver Cloud
  Platform의 Maps API 도메인 이전**(`naveropenapi.apigw.ntruss.com` → `maps.apigw.ntruss.com`)
  임을 밝혀내고 `src/app/api/geocode/route.ts` 를 수정 → 실제 주소로 정상 좌표 반환 확인
  (자세한 내용은 ENVIRONMENT_VARIABLES.md 참고)

### 라우트 응답 코드 확인 (curl)

| 경로 | 결과 | 비고 |
|---|---|---|
| `/` | 200 | |
| `/recommend` | 200 | |
| `/map` | 200 | |
| `/restaurants` | 200 | 실제 등록 가게 카드 렌더링 확인 |
| `/restaurants/[실제id]` | 200 | 실제 DB 데이터 렌더링 확인 |
| `/login`, `/signup` | 200 | |
| `/support`, `/terms`, `/privacy`, `/delete-account` | 200 | 비로그인 접근 가능 확인 |
| `/location-policy`, `/marketing-consent`, `/business-terms`, `/community-guidelines`, `/privacy/children` | 200 | |
| `/mypage`, `/owner`, `/admin` (비로그인 상태) | **307 → `/login`** | 서버 컴포넌트 단계에서 인증 미들웨어가 올바르게 리디렉션함을 확인 |
| 존재하지 않는 경로 | **404** | 커스텀 404 페이지 정상 동작 |

## ⚠️ 코드 레벨로 구현을 완료했으나, 실제 브라우저 클릭으로 검증하지 못한 것

이 세션에는 브라우저 자동화 도구가 연결되어 있지 않아 아래 흐름은 실제 클릭 테스트를 하지 못했습니다.
로직/RLS 정책/타입은 검토했지만, **배포 후 실제 브라우저에서 한 번은 직접 확인하는 것을 권장합니다.**

- 회원가입 → 이메일 인증 → 로그인 → 재로그인 시 세션 유지
- 비밀번호 재설정 이메일 → 링크 클릭 → 새 비밀번호 설정
- 위치 권한 허용/거부 시 실제 브라우저 동작
- 메뉴 뽑기 → 저장(찜) → 마이페이지에서 기록 확인
- 사장님 가게 등록 신청 → 이미지 업로드 → 관리자 승인 → 지도/추천에 노출
- 관리자 승인/반려/신고 처리 버튼 클릭 흐름
- 계정 삭제 버튼 클릭 후 실제 Supabase Auth 사용자 삭제 확인

이 항목들에 대해 실제 프로덕션 계정을 만들어 자동 테스트하는 대신, **운영 데이터를 오염시키지
않기 위해 의도적으로 실행하지 않았습니다.** (예: 실제 계정 생성 후 삭제 API로 정리하는 방법도
검토했으나, 이메일 인증이 켜져 있어 API만으로는 로그인까지 완결할 수 없었습니다.)

## 알려진 제약사항 및 배포 후 발견/해결한 이슈

1. ~~**Naver Geocoding**~~ → **해결됨(2026-07-14)**. NCP가 Maps API 도메인을 이전한 것이 원인이었고
   `src/app/api/geocode/route.ts` 를 새 도메인으로 수정해 정상 동작 확인. 자세한 내용은
   ENVIRONMENT_VARIABLES.md 참고.
2. **가게 좌표 오류 실사례 발견 및 수정 기능 추가**: 운영 데이터 중 "부팔라 리스토란테 피제리아"의
   주소는 과천시인데 좌표는 강남역 기본값으로 저장되어 있던 것을 발견. 기존에는 이미 승인된 가게의
   좌표를 고칠 UI가 없어서, `/admin/restaurants`에 좌표 수동 수정 + 주소 기반 재조회 기능을 추가함.
3. **`analytics_events` 테이블 / `restaurants.image_url` 컬럼**: 2026-07-14 재확인 결과 이미 생성되어
   있음(운영자가 `migrations_web.sql`을 실행한 것으로 보입니다).
4. **Storage 버킷(`menu-images`, `business-licenses`)**: 2026-07-14 재확인 결과 **아직 생성되지
   않음**. `migrations_web.sql` 중 Storage 버킷 생성 부분만 별도로 다시 실행이 필요합니다
   (SQL Editor에서 파일 전체를 다시 실행해도 안전합니다 — `ON CONFLICT DO NOTHING` 처리되어 있음).
   이 상태에서는 메뉴/가게 이미지, 사업자등록증 업로드 시 오류가 발생합니다.

## 회귀 테스트 (기존 Flutter 앱)

이번 작업은 **Flutter 앱의 코드/DB 스키마를 변경하지 않았습니다** (`ALTER TABLE ADD COLUMN`,
`CREATE TABLE IF NOT EXISTS` 등 추가 전용). 따라서 기존 앱 동작에 영향이 없을 것으로 판단되며,
`flutter analyze` 등 Flutter 측 테스트는 별도로 실행하지 않았습니다(코드 변경이 없으므로).
