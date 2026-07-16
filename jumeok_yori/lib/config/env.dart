import 'package:flutter_dotenv/flutter_dotenv.dart';

/// .env 파일에서 환경변수를 읽는 헬퍼
/// 키가 없거나 비어 있으면 빈 문자열 반환
class Env {
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // USE_SUPABASE=true 일 때만 실제 Supabase 사용
  static bool get useSupabase {
    final val = dotenv.env['USE_SUPABASE']?.toLowerCase() ?? 'false';
    return val == 'true';
  }

  /// Supabase 연결 가능 여부 (URL과 키가 모두 채워져 있어야 함)
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('여기에') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('여기에');

  // ── 네이버 지도 / Geocoding (주먹지도) ─────────────────────
  static String get naverMapClientId => dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';
  static String get naverMapClientIdAndroid =>
      dotenv.env['NAVER_MAP_CLIENT_ID_ANDROID'] ?? '';
  static String get naverMapClientIdIos =>
      dotenv.env['NAVER_MAP_CLIENT_ID_IOS'] ?? '';
  static String get naverMapClientSecret =>
      dotenv.env['NAVER_MAP_CLIENT_SECRET'] ?? '';
  static bool get isNaverGeocodingConfigured =>
      naverMapClientId.isNotEmpty && naverMapClientSecret.isNotEmpty;
}
