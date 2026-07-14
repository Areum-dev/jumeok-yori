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

## 확인 필요 (운영자 조치 필요)

로컬에서 테스트한 결과, 현재 Naver Cloud Platform 자격 증명으로 지오코딩 API 호출 시
`"Permission Denied: A subscription to the API is required."` (401) 오류가 발생했습니다.
Flutter 앱과 동일한 키를 사용했음에도 발생한 것으로 보아 **코드 문제가 아니라 Naver Cloud Platform
콘솔에서 Geocoding/Web Dynamic Map 서비스 구독이 활성화되어 있지 않거나 만료된 것으로 보입니다.**

조치 방법:
1. https://console.ncloud.com 로그인 → AI·Application Service → Maps
2. 사용 중인 Application(Client ID: `gtc1th04fc`)에 "Geocoding" 과 "Web Dynamic Map" 서비스가
   활성화되어 있는지, 결제 수단이 유효한지 확인
3. 활성화 후 재테스트. 활성화 전까지는 웹에서 지도가 자동으로 목록 보기로 대체되고,
   주소 검색으로 기준 위치를 잡는 기능은 오류 메시지를 보여줍니다(GPS 기반 위치와 강남역 기본 위치는 정상 동작).

## Vercel에 설정할 환경변수

Vercel Dashboard > Project > Settings > Environment Variables 에 위 7개를 모두 등록하세요.
`SUPABASE_SERVICE_ROLE_KEY` 와 `NAVER_MAP_CLIENT_SECRET` 은 반드시 "Sensitive" 로 표시하고
`NEXT_PUBLIC_` 접두사를 붙이지 마세요.
