/// 앱 전역 상수 설정
class AppConfig {
  /// 개발 모드에서 등록 메뉴를 자동 승인할지 여부 (운영에서는 false)
  static const bool autoApproveMenuInDev = false;

  /// 개발 모드에서 샘플 식당 사용 여부 (운영에서는 false)
  static const bool useSampleRestaurantsInDev = false;

  /// 등록 메뉴가 없을 때 스타터 메뉴로 폴백할지 여부
  static const bool useStarterMenusFallback = true;

  /// 공유 기능 활성화
  static const bool enableShare = true;

  /// 신고 기능 활성화
  static const bool enableReports = true;

  /// 이메일+비밀번호 로그인 활성화
  static const bool enableEmailPasswordAuth = true;

  /// 이메일 OTP 로그인 활성화 (OTP 방식 사용 안 함)
  static const bool enableEmailOtp = false;

  /// 관리자 이메일 (이 계정으로 로그인하면 관리자 권한)
  static const String adminEmail = '1vpsrnls@gmail.com';

  /// 기본 위치 (강남역)
  static const double defaultLat = 37.4979;
  static const double defaultLng = 127.0276;
  static const String defaultLocationLabel = '강남역';

  // ── 주먹지도 (Jumeok Map) ─────────────────────────────────
  static const bool enableJumeokMap = true;
  static const bool useMapFallbackWhenApiMissing = true;
  static const bool showOnlyApprovedStoresOnMap = true;
  static const bool enableNaverGeocoding = true;
  static const bool allowManualLatLngEditByAdmin = true;

  // ── 사장님/분석 ───────────────────────────────────────────
  static const bool autoApproveOwnerMenusAfterStoreApproved = true;
  static const bool enableAnalytics = true;
}
