/**
 * 앱 전역 상수. jumeok_yori(Flutter) lib/config/app_config.dart 와 동일한 값을 사용합니다.
 */
export const AppConfig = {
  /** 관리자 이메일 (DB role='admin' 과 함께 사용되는 참고용 값. 실제 권한 판단은 반드시 DB role 기준) */
  adminEmail: "1vpsrnls@gmail.com",

  /** 기본 위치 (강남역) — 위치 권한 거부/실패 시 사용 */
  defaultLat: 37.4979,
  defaultLng: 127.0276,
  defaultLocationLabel: "강남역",

  categoryOptions: ["전체", "한식", "중식", "일식", "양식", "분식", "패스트푸드", "카페/디저트"] as const,

  supportEmail: process.env.NEXT_PUBLIC_SUPPORT_EMAIL || "1vpdrnls@gmail.com",
} as const;
