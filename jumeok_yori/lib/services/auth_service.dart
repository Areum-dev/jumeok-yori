import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/profile.dart';

/// Supabase 인증 래퍼. Supabase 미초기화 시 안전하게 동작합니다.
class AuthService {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null; // 초기화 안 됨 (mock 모드)
    }
  }

  bool get isAvailable => _client != null;

  User? getCurrentUser() => _client?.auth.currentUser;

  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  Future<void> signUp(
    String email,
    String password, {
    String? displayName,
  }) async {
    final client = _client;
    if (client == null) throw '서버에 연결할 수 없습니다.';
    try {
      await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
    } on AuthException catch (e) {
      throw _koreanError(e.message);
    } catch (_) {
      throw '회원가입 중 오류가 발생했습니다.';
    }
  }

  Future<void> signIn(String email, String password) async {
    final client = _client;
    if (client == null) throw '서버에 연결할 수 없습니다.';
    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw _koreanError(e.message);
    } catch (_) {
      throw '로그인 중 오류가 발생했습니다.';
    }
  }

  /// 카카오 로그인 (Supabase OAuth 방식). Kakao Native SDK 를 직접 쓰지 않고
  /// Supabase 가 카카오 인증 서버로 리디렉션한 뒤, 앱이 [kakaoRedirectTo] 딥링크로
  /// 복귀하면 supabase_flutter 가 내부적으로 세션을 확립합니다.
  ///
  /// 이 메서드가 반환하는 bool 은 "로그인이 완료됐다"는 뜻이 아니라
  /// "카카오 로그인 페이지를 여는 데 성공했다"는 뜻입니다(Supabase SDK 공식 동작).
  /// 실제 로그인 성공 여부는 authStateChanges 스트림의 signedIn 이벤트로 판단해야
  /// 합니다.
  static const kakaoRedirectTo = 'com.jumeokyori.app://login-callback';

  /// scopes 파라미터를 넘기지 않습니다. Supabase 는 클라이언트가 보낸
  /// scopes 를 대체(override)가 아니라 Dashboard(Authentication > Providers >
  /// Kakao)에 저장된 scope 뒤에 그대로 이어붙입니다(append). 그래서 예전에
  /// scopes: 'profile_nickname profile_image' 를 넘겼을 때 실제 인가 URL은
  /// "{Dashboard 설정값} profile_nickname profile_image" 형태로 나갔고,
  /// Dashboard 쪽에 이미 account_email 이 남아있어 KOE205 가 계속 발생했습니다.
  /// account_email 을 실제로 제거하려면 Supabase Dashboard 의 Kakao Provider
  /// 설정에서 scope 값을 직접 고쳐야 하며, 앱 코드에서는 scopes 를 아예
  /// 넘기지 않는 것이 가장 안전합니다(중복 append 도 함께 방지됨).
  /// 인증 화면을 항상 외부 브라우저(iOS: Safari / SFAuthenticationSession,
  /// Android: Chrome Custom Tab)로 강제 실행합니다. 기본값인
  /// LaunchMode.platformDefault 를 iOS 에서 그대로 두면 앱 내장 웹뷰로
  /// 열리는데, 이 내장 웹뷰가 카카오 로그인 페이지를 제대로 로드하지 못하고
  /// 흰 화면만 남는 문제가 있었습니다(구글 로그인은 Android 한정으로 SDK가
  /// 내부적으로 이미 externalApplication 을 강제하고 있는데, 카카오는 그런
  /// 예외 처리가 없어 iOS 에서 기본값을 그대로 씁니다). Android 는 기존에도
  /// 정상 작동했고 externalApplication 으로 바꿔도 동작 방식은 동일(외부
  /// 브라우저로 열림)하므로 플랫폼 분기 없이 공통 적용합니다.
  Future<bool> signInWithKakao() async {
    final client = _client;
    if (client == null) throw '서버에 연결할 수 없습니다.';
    try {
      return await client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: kakaoRedirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      throw _koreanError(e.message);
    } catch (_) {
      throw '카카오 로그인 중 오류가 발생했습니다.';
    }
  }

  /// 비밀번호 재설정 메일 전송.
  Future<void> resetPassword(String email) async {
    final client = _client;
    if (client == null) throw '서버에 연결할 수 없습니다.';
    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw _koreanError(e.message);
    } catch (_) {
      throw '비밀번호 재설정 메일 전송 중 오류가 발생했습니다.';
    }
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  /// 현재 로그인한 사용자의 프로필 조회 (없으면 null)
  Future<Profile?> getCurrentProfile() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return null;
    try {
      final res = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (res == null) {
        // 트리거 미동작 대비 fallback. 카카오 계정은 email 이 없을 수 있으므로
        // (account_email scope 미요청) 빈 문자열이 되지 않도록 처리한다.
        // (my_page_screen 등에서 displayName.characters.first 를 쓰는데
        // 빈 문자열이면 예외가 발생한다.)
        final email = user.email;
        final meta = user.userMetadata;
        final metaNickname = _metaString(meta, [
          'full_name',
          'name',
          'nickname',
        ]);
        return Profile(
          id: user.id,
          email: email ?? '',
          displayName:
              metaNickname ??
              ((email != null && email.contains('@'))
                  ? email.split('@').first
                  : '카카오 사용자'),
          avatarUrl: _metaString(meta, ['avatar_url', 'picture']),
          role: _roleFromEmail(email),
          createdAt: DateTime.now(),
        );
      }
      final profile = Profile.fromJson(res);
      // 관리자 이메일이면 role 보정 (DB role 우선)
      if (profile.role != 'admin' && profile.email == AppConfig.adminEmail) {
        return profile.copyWith(role: 'admin');
      }
      return profile;
    } catch (_) {
      return null;
    }
  }

  String _roleFromEmail(String? email) =>
      email == AppConfig.adminEmail ? 'admin' : 'user';

  /// OAuth 프로바이더가 넘겨준 user_metadata 에서 후보 키를 순서대로 찾아
  /// 첫 번째로 존재하는 비어있지 않은 문자열을 반환합니다. 없으면 null.
  String? _metaString(Map<String, dynamic>? meta, List<String> keys) {
    if (meta == null) return null;
    for (final key in keys) {
      final value = meta[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  String _koreanError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (m.contains('already registered') ||
        m.contains('already been registered')) {
      return '이미 가입된 이메일입니다.';
    }
    if (m.contains('password') && m.contains('6')) {
      return '비밀번호는 6자 이상이어야 합니다.';
    }
    if (m.contains('email') && m.contains('confirm')) {
      return '이메일 인증이 필요합니다. 메일함을 확인해주세요.';
    }
    if (m.contains('rate limit')) {
      return '잠시 후 다시 시도해주세요.';
    }
    return '인증 오류가 발생했습니다. 다시 시도해주세요.';
  }
}
