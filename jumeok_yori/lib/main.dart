import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. .env 파일 로드
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ .env 로드 실패, mock 모드로 계속: $e');
  }

  // 2. Supabase 초기화
  bool supabaseReady = false;
  if (Env.useSupabase && Env.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      );
      supabaseReady = true;
      debugPrint('✅ Supabase 초기화 완료');
    } catch (e) {
      debugPrint('❌ Supabase 초기화 실패, mock 모드로 계속: $e');
    }
  } else {
    debugPrint('ℹ️ mock 모드로 실행 중');
  }

  // 3. 네이버 지도 SDK 초기화 (runApp 전에 반드시 수행)
  //    Client ID 는 코드에 하드코딩하지 않고 .env(Env)에서 읽는다.
  // API 키 전체를 로그에 출력하지 않도록 마스킹
  final naverClientId = Env.naverMapClientId;
  final maskedClientId = naverClientId.length > 4
      ? '${naverClientId.substring(0, 4)}${'*' * (naverClientId.length - 4)}'
      : '****';
  debugPrint('[NaverMap] clientId="$maskedClientId"');
  try {
    await FlutterNaverMap().init(
      clientId: Env.naverMapClientId,
      onAuthFailed: (e) => debugPrint('❌ 네이버 지도 인증 실패: $e'),
    );
    debugPrint('✅ 네이버 지도 SDK 초기화 완료');
  } catch (e, st) {
    debugPrint('⚠️ 네이버 지도 SDK 초기화 실패: $e\n$st');
  }

  runApp(JumeokYoriApp(supabaseReady: supabaseReady));
}
