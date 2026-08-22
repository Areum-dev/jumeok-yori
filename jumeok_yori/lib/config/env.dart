import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 앱 asset의 공개 설정만 읽는다. Client Secret은 이 파일에 포함하지 않는다.
class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

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
}
