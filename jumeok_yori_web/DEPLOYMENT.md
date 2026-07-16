# 배포 가이드

## 현재 상태

- `npm run build` 프로덕션 빌드 **성공** (TypeScript 오류 0건, ESLint 오류 0건)
- Git 저장소 초기화 및 로컬 커밋 완료
- **Vercel CLI로 이 PC에서 직접 배포를 시도했으나 실패했습니다.** 원인과 해결 방법은 아래 참고.

### 배포가 자동으로 완료되지 못한 이유 (중요)

이 PC의 Windows 컴퓨터 이름이 한글(`재경트북`)로 되어 있는데, Vercel CLI 54.15.1이 API 요청 헤더에
컴퓨터 이름을 그대로 넣다가 "not a legal HTTP header value" 오류로 **모든 명령(`vercel login`,
`vercel whoami`, `vercel deploy` 등)이 실행 전에 즉시 실패**합니다. 환경변수로 우회를 시도했지만
Node.js가 OS 레벨에서 직접 컴퓨터 이름을 읽어오기 때문에 우회되지 않았습니다. 또한 이 환경에는
GitHub CLI(`gh`)와 저장된 GitHub 자격증명이 없어 자동으로 원격 저장소를 만들어 푸시할 수도 없었습니다.

이 문제는 코드 문제가 아니라 **로컬 환경 문제**이므로, 아래 두 가지 방법 중 하나로 직접 배포를 완료해주세요.

---

## 방법 A: Vercel 웹사이트로 배포 (권장, GitHub 필요)

1. GitHub에 새 저장소를 만듭니다 (예: `jumeok_yori_web`).
2. 아래 명령으로 이 프로젝트를 푸시합니다 (터미널에서 `jumeok_yori_web` 폴더 안에서 실행):

   ```bash
   git remote add origin https://github.com/<본인계정>/jumeok_yori_web.git
   git branch -M main
   git push -u origin main
   ```

   (Windows에서 GitHub 로그인 창이 뜨면 로그인하세요.)

3. https://vercel.com 접속 → 로그인 → **Add New → Project**
4. 방금 만든 GitHub 저장소를 Import
5. **Environment Variables** 에 [ENVIRONMENT_VARIABLES.md](./ENVIRONMENT_VARIABLES.md) 의 7개 값을 모두 입력
   (`SUPABASE_SERVICE_ROLE_KEY`, `NAVER_MAP_CLIENT_SECRET` 은 Sensitive 체크)
6. **Deploy** 클릭
7. 배포 완료 후 발급된 도메인(예: `https://jumeok_yori_web.vercel.app`)을 확인합니다.
8. `NEXT_PUBLIC_SITE_URL` 환경변수를 방금 발급된 실제 도메인으로 다시 설정하고 재배포합니다.

## 방법 B: 다른 PC/환경에서 Vercel CLI 사용

컴퓨터 이름에 한글이 없는 다른 Windows PC, Mac, 또는 WSL(Windows Subsystem for Linux)이 있다면:

```bash
npm install -g vercel
cd jumeok_yori_web
vercel login
vercel link
vercel env add   # 환경변수 7개를 순서대로 입력
vercel --prod
```

## 배포 후 필수로 해야 하는 설정 (양쪽 방법 공통)

### 1. Supabase Auth Redirect URL 등록

Supabase Dashboard → Authentication → URL Configuration:

- **Site URL**: 배포된 실제 도메인
- **Redirect URLs**: `https://<배포도메인>/auth/callback` 추가

이 설정이 없으면 회원가입 이메일 인증 링크, 비밀번호 재설정 링크가 깨집니다.

### 2. Supabase 마이그레이션 실행

[SUPABASE_SCHEMA.md](./SUPABASE_SCHEMA.md) 참고 — `supabase/migrations_web.sql` 을
SQL Editor에서 실행해야 이미지 업로드/사장님 통계/50개 기본 메뉴가 정상 동작합니다.

### 3. 배포 후 확인할 것 (체크리스트)

- [ ] 배포 URL 접속 시 홈페이지 정상 표시
- [ ] `/privacy`, `/terms`, `/delete-account`, `/support` 비로그인 상태로 접속 가능
- [ ] 회원가입 → 이메일 인증 → 로그인 정상 동작
- [ ] `/recommend` 에서 메뉴 뽑기 동작
- [ ] `/map` 접속 시 지도 또는 목록(fallback) 정상 표시
- [ ] 모바일 화면 크기에서 반응형 정상 확인
- [ ] 새로고침 시 404/라우팅 오류 없음
- [ ] 존재하지 않는 경로 접속 시 커스텀 404 페이지 표시

## Google Play 제출용 URL

[GOOGLE_PLAY_RELEASE_URLS.md](./GOOGLE_PLAY_RELEASE_URLS.md) 참고. 배포 완료 후 실제 도메인으로
URL을 채워 Google Play Console에 입력하세요.
