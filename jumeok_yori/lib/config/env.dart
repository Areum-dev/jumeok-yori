/// 빌드 시 --dart-define-from-file=.env 로 전달되는 공개 설정만 읽는다.
class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  // USE_SUPABASE=true 일 때만 실제 Supabase 사용
  static bool get useSupabase {
    const val = String.fromEnvironment('USE_SUPABASE', defaultValue: 'false');
    return val == 'true';
  }

  /// Supabase 연결 가능 여부 (URL과 키가 모두 채워져 있어야 함)
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('여기에') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('여기에');

  // ── 네이버 지도 / Geocoding (주먹지도) ─────────────────────
  static const String naverMapClientId = String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID',
  );
  static const String naverMapClientIdAndroid = String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID_ANDROID',
  );
  static const String naverMapClientIdIos = String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID_IOS',
  );
}
