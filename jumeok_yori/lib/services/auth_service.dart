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

  Future<void> signUp(String email, String password,
      {String? displayName}) async {
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

  /// 카카오 디벨로퍼스 동의항목과 정확히 일치하는 scope만 요청합니다.
  /// account_email 은 카카오 디벨로퍼스에서 "권한 없음"으로 설정돼 있어,
  /// 이 값을 요청(또는 Supabase 기본 scope에 맡겨 암묵적으로 요청)하면
  /// 카카오 서버가 KOE205(동의항목에 없는 scope 요청)로 로그인을 거부합니다.
  /// scopes 를 명시적으로 지정해 Supabase 의 기본 scope 목록을 덮어씁니다.
  static const _kakaoScopes = 'profile_nickname profile_image';

  Future<bool> signInWithKakao() async {
    final client = _client;
    if (client == null) throw '서버에 연결할 수 없습니다.';
    try {
      return await client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: kakaoRedirectTo,
        scopes: _kakaoScopes,
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
        return Profile(
          id: user.id,
          email: email ?? '',
          displayName: (email != null && email.contains('@'))
              ? email.split('@').first
              : '카카오 사용자',
          role: _roleFromEmail(email),
          createdAt: DateTime.now(),
        );
      }
      final profile = Profile.fromJson(res);
      // 관리자 이메일이면 role 보정 (DB role 우선)
      if (profile.role != 'admin' &&
          profile.email == AppConfig.adminEmail) {
        return profile.copyWith(role: 'admin');
      }
      return profile;
    } catch (_) {
      return null;
    }
  }

  String _roleFromEmail(String? email) =>
      email == AppConfig.adminEmail ? 'admin' : 'user';

  String _koreanError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (m.contains('already registered') || m.contains('already been registered')) {
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
