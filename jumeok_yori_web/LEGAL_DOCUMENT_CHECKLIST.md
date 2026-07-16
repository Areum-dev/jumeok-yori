# 법률 문서 점검 체크리스트

웹 법률 페이지(`/privacy`, `/terms`, `/delete-account`, `/support` 및 보조 페이지)는 모두
`jumeok_yori/lib/legal/*.md` (운영자가 이미 작성해 둔 기존 문서)를 **그대로 재사용**했습니다.
새로 창작하지 않았고, 확인되지 않은 사업자 정보를 임의로 만들어 넣지 않았습니다.

## 문서 ↔ 웹 페이지 매핑

| 원본 파일 (`jumeok_yori/lib/legal/`) | 웹 경로 |
|---|---|
| `terms.md` | `/terms` |
| `privacy.md` | `/privacy` |
| `withdrawal.md` | `/delete-account` (하단에 전문 포함) |
| `customer-support.md` | `/support` (하단에 전문 포함) |
| `location-policy.md` | `/location-policy` |
| `marketing.md` | `/marketing-consent` |
| `merchant-policy.md` | `/business-terms` |
| `community-policy.md` | `/community-guidelines` |
| `youth-protection.md` | `/privacy/children` |
| `location-consent.md`, `privacy-consent.md` | 회원가입 화면의 동의 체크박스 안내 문구에 반영 (전용 페이지는 만들지 않음) |
| `copyright.md`, `report-policy.md` | 각각 `/terms`(저작권 조항), `/community-guidelines`(신고 절차)에 이미 포함되어 있어 별도 페이지 미생성 |
| `data-safety-google.md` | 웹 페이지 아님 — `GOOGLE_PLAY_RELEASE_URLS.md` 작성에 활용 |
| `privacy-apple.md` | 웹 페이지 아님 — iOS 출시 시 참고용으로 원본 유지 |

## 운영자가 반드시 실제 정보로 교체해야 하는 항목

`jumeok_yori/lib/legal/*.md` 원본 자체에 아직 채워지지 않은 항목들입니다 (웹에서 임의로 지어내지
않고 원본 그대로 노출했습니다):

- [ ] 사업자명 (상호)
- [ ] 사업자등록번호
- [ ] 대표자명
- [ ] 사업장 주소
- [ ] 개인정보 보호책임자 실명/직책/직통 연락처 (`privacy.md` 제9조는 현재 "주먹요리 운영팀"으로만 표기)
- [ ] 통신판매업 신고번호 (해당하는 경우)

이 항목들이 채워지면 `jumeok_yori/lib/legal/*.md` 원본만 수정하면 됩니다. 웹은 해당 파일을
`src/content/legal/` 로 복사해 그대로 렌더링하므로, **원본을 수정한 뒤 해당 파일을 다시
`jumeok_yori_web/src/content/legal/` 로 복사하고 재배포**하면 반영됩니다.

## 각 문서에 이미 포함되어 있는 필수 항목 확인

각 법률 문서 원본에 다음이 이미 기재되어 있음을 확인했습니다.

- [x] 작성일 (2026-07-13)
- [x] 시행일 (2026-07-13)
- [x] 버전 (1.0.0)
- [x] 변경이력 (아직 1개 버전만 존재하므로 "이전 방침 없음"으로 명시됨)

## 확인되지 않아 임의로 작성하지 않은 것

- 사업자 등록 정보 일체 (위 목록)
- "24시간 이내 답변" 등 확인되지 않은 응답 시간 — `/support` 페이지에는 `customer-support.md`에
  실제로 문서화된 처리 기간(영업일 기준 3~10일)만 표시했고, 확인되지 않은 문구는 추가하지 않았습니다.
- 광고 포함 여부 — `GOOGLE_PLAY_RELEASE_URLS.md`에 "확인 필요"로 표시

## 웹에서 새로 반영한 사항

- 계정 삭제가 실제로 동작하도록 서버 API(`/api/account/delete`)를 구현했습니다. 기존 Flutter 앱의
  회원탈퇴 화면은 `profiles.phone`, `profiles.deleted_at`, `profiles.deletion_reason` 컬럼에
  값을 쓰려고 시도하지만, 실제 운영 DB에는 이 컬럼들이 없어 (`try/catch`로 조용히 무시되어) 계정이
  실제로는 삭제되지 않고 로그아웃만 되는 상태였던 것으로 확인됩니다. 웹에서는 이 문제를 반복하지 않도록
  service role을 사용해 `auth.users` 를 실제로 삭제하고, 연관된 가게/메뉴/추천기록/찜 데이터의 관계를
  검토해 안전하게 처리하도록 구현했습니다 (자세한 내용은 `src/app/api/account/delete/route.ts` 주석 참고).
