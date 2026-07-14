# 환경변수 목록

`.env.example` 을 복사해 `.env.local` 을 만드세요. 로컬 개발용 값은 이미 `.env.local` 에 채워져 있습니다
(Flutter 앱의 `.env`와 동일한 Supabase 프로젝트 값). **`.env.local` 은 Git에 커밋되지 않습니다.**

| 변수명 | 공개 여부 | 용도 | 비고 |
|---|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | 공개 (브라우저 노출) | Supabase 프로젝트 URL | Flutter `.env`의 `SUPABASE_URL`과 동일해야 함 |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | 공개 | Supabase anon/publishable key | Flutter `.env`의 `SUPABASE_ANON_KEY`와 동일해야 함. RLS로 보호되므로 공개되어도 안전 |
| `SUPABASE_SERVICE_ROLE_KEY` | **비공개(서버 전용)** | 계정 삭제 API(`/api/account/delete`)에서만 사용 | Supabase Dashboard > Settings > API > `service_role` (secret) 키. **절대 `NEXT_PUBLIC_` 접두사 붙이지 말 것. 브라우저 코드에 절대 포함 금지** |
| `NEXT_PUBLIC_NAVER_MAP_CLIENT_ID` | 공개 | 주먹지도(Naver Maps JS API) 로딩용 Client ID | Flutter `.env`의 `NAVER_MAP_CLIENT_ID`와 동일. **Naver Cloud Platform 콘솔에서 해당 Application에 "Web Dynamic Map" 서비스가 별도로 활성화되어 있어야 함 (확인 필요, 아래 참고)** |
| `NAVER_MAP_CLIENT_SECRET` | **비공개(서버 전용)** | 주소→좌표 변환(`/api/geocode`)에서만 사용 | Flutter `.env`의 `NAVER_MAP_CLIENT_SECRET`과 동일. 브라우저에 노출 금지, 서버 API 라우트를 통해서만 호출 |
| `NEXT_PUBLIC_SUPPORT_EMAIL` | 공개 | 고객지원/계정삭제 문의 이메일 | 기본값 `1vpdrnls@gmail.com` |
| `NEXT_PUBLIC_SITE_URL` | 공개 | 배포 도메인 (메타데이터, sitemap, robots.txt) | 로컬: `http://localhost:3000`, 운영: 실제 배포 URL로 교체 |

## 해결된 이슈: Naver Geocoding 도메인 변경 (2026-07-14)

처음엔 `naveropenapi.apigw.ntruss.com` (jumeok_yori Flutter 앱과 동일 도메인)으로 호출했으나
운영 계정에서 `"Permission Denied: A subscription to the API is required."` (401) 오류가 계속
발생했습니다. 콘솔에서 Web Dynamic Map/Geocoding 서비스와 결제 수단을 모두 확인한 뒤에도
동일한 오류가 나서 두 도메인을 직접 비교 테스트한 결과, **Naver Cloud Platform이 Maps API를
새 도메인(`maps.apigw.ntruss.com`)으로 이전한 것으로 확인**되었습니다. 새 도메인 + 소문자 헤더
(`x-ncp-apigw-api-key-id`, `x-ncp-apigw-api-key`)로 호출하니 정상 동작했습니다.

`src/app/api/geocode/route.ts` 를 새 도메인으로 수정해 반영했습니다.

**Flutter 앱(`jumeok_yori/lib/services/naver_geocoding_service.dart`)은 여전히 구 도메인을
사용 중이므로, 같은 문제를 겪고 있을 가능성이 있습니다.** 앱 쪽도 도메인을
`https://maps.apigw.ntruss.com/map-geocode/v2/geocode` 로 바꾸는 것을 검토해보세요
(이번 작업 범위상 Flutter 코드는 수정하지 않았습니다).

## Vercel에 설정할 환경변수

Vercel Dashboard > Project > Settings > Environment Variables 에 위 7개를 모두 등록하세요.
`SUPABASE_SERVICE_ROLE_KEY` 와 `NAVER_MAP_CLIENT_SECRET` 은 반드시 "Sensitive" 로 표시하고
`NEXT_PUBLIC_` 접두사를 붙이지 마세요.
