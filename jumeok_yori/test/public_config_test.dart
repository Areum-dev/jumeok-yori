import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('공개 설정 asset에는 필수 공개값만 있고 Client Secret은 없다', () async {
    await dotenv.load(fileName: 'assets/config.env');

    expect(dotenv.env['USE_SUPABASE'], 'true');
    expect(dotenv.env['SUPABASE_URL'], isNotEmpty);
    expect(dotenv.env['SUPABASE_ANON_KEY'], isNotEmpty);
    expect(dotenv.env['NAVER_MAP_CLIENT_ID'], isNotEmpty);
    expect(dotenv.env.containsKey('NAVER_MAP_CLIENT_SECRET'), isFalse);
  });
}
