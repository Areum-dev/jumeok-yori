# 처음 설정하기 (초보자용)

## 1. 준비물

- Node.js 20.9 이상 (설치되어 있음: `node -v`로 확인)
- 이 저장소를 내려받은 폴더: `jumeok_yori_web`

## 2. 패키지 설치

터미널에서 `jumeok_yori_web` 폴더로 이동한 뒤:

```bash
npm install
```

## 3. 환경변수 설정

`.env.example` 을 복사해 `.env.local` 파일을 만듭니다. 이미 로컬 개발용 값이 채워진
`.env.local` 이 준비되어 있다면 이 단계는 건너뛰어도 됩니다. 값 설명은
[ENVIRONMENT_VARIABLES.md](./ENVIRONMENT_VARIABLES.md) 를 참고하세요.

`SUPABASE_SERVICE_ROLE_KEY` 만은 보안상 비워둔 채로 넘겨받았을 수 있습니다.
Supabase Dashboard → Settings → API → `service_role` 값을 복사해 채워 넣어야
계정 삭제 기능(`/delete-account`)이 동작합니다.

## 4. Supabase 마이그레이션 실행 (최초 1회, 운영자 작업)

[SUPABASE_SCHEMA.md](./SUPABASE_SCHEMA.md) 의 안내대로 `supabase/migrations_web.sql` 을
Supabase Dashboard → SQL Editor 에서 실행하세요. 실행하지 않아도 대부분의 기능은 동작하지만,
이미지 업로드/사장님 통계/50개 기본 메뉴는 이 마이그레이션 이후에 정상 동작합니다.

## 5. 개발 서버 실행

```bash
npm run dev
```

브라우저에서 http://localhost:3000 접속.

## 6. 빌드 확인

배포 전에는 항상 아래 명령으로 빌드가 성공하는지 확인하세요.

```bash
npm run build
```

## 7. Supabase Auth 리디렉션 설정 (운영자 작업)

Supabase Dashboard → Authentication → URL Configuration 에서:

- **Site URL**: 배포 도메인 (예: `https://jumeok-yori.vercel.app`)
- **Redirect URLs** 에 다음을 모두 추가:
  - `http://localhost:3000/auth/callback` (로컬 개발용)
  - `https://<배포도메인>/auth/callback` (운영용)

이 설정이 없으면 회원가입 이메일 인증, 비밀번호 재설정 링크가 올바른 페이지로 돌아오지 않습니다.

## 8. 배포

[DEPLOYMENT.md](./DEPLOYMENT.md) 를 참고하세요.
