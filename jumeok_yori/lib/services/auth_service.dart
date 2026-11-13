import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/profile.dart';

/// 사용자가 로그인 시트를 직접 닫았을 때 던지는 표시용 예외.
/// 화면에서는 오류 문구 없이 조용히 무시한다.
class AuthCanceled implements Exception {
  const AuthCanceled();
}

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

  /// 이메일 인증 메일/비밀번호 재설정 메일의 링크가 최종적으로 돌아올 딥링크.
  /// 카카오 OAuth 복귀와 동일한 scheme 을 재사용한다 (이미 Android
  /// intent-filter / iOS CFBundleURLTypes 에 등록돼 있어 추가 네이티브
  /// 설정이 필요 없고, 카카오 로그인에서 이미 정상 동작이 검증된 값이다).
  ///
  /// 이 값을 명시적으로 넘기지 않으면 Supabase 는 Dashboard 의 기본 "Site URL"
  /// 로 리디렉션하는데, Site URL 이 실제로 서비스되지 않는 주소(예: 예전
  /// 웹 프로젝트 주소나 localhost)로 설정돼 있으면 메일 링크를 열었을 때
  /// 404 가 뜬다 (계정 인증 자체는 Supabase 서버에서 이미 처리된 뒤라
  /// 앱으로 돌아가면 로그인은 돼 있는 것처럼 보이지만, 링크를 연 순간
  /// 사용자에게는 깨진 것처럼 보인다). Supabase Dashboard 의
  /// Authentication > URL Configuration > Redirect URLs 허용 목록에
  /// 이 값이 반드시 포함돼 있어야 실제로 적용된다(카카오 로그인 설정 때
  /// 이미 등록해뒀다면 별도 조치 불필요).
  static const appDeepLinkRedirectTo = 'com.jumeokyori.app://login-callback';

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
        emailRedirectTo: appDeepLinkRedirectTo,
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
  /// Supabase 가 카카오 인증 서버로 리디렉션한 뒤, 앱이 [appDeepLinkRedirectTo]
  /// 딥링크로 복귀하면 supabase_flutter 가 내부적으로 세션을 확립합니다.
  ///
  /// 이 메서드가 반환하는 bool 은 "로그인이 완료됐다"는 뜻이 아니라
  /// "카카오 로그인 페이지를 여는 데 성공했다"는 뜻입니다(Supabase SDK 공식 동작).
  /// 실제 로그인 성공 여부는 authStateChanges 스트림의 signedIn 이벤트로 판단해야
  /// 합니다.

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
  ///
  /// iOS 는 위 방식 대신 ASWebAuthenticationSession(앱 안 로그인 시트)을 쓴다.
  /// 2026-11 App Store 심사(가이드라인 4.0)에서 "카카오 로그인 시 기본 브라우저로
  /// 이동한다"는 이유로 반려되었기 때문. ASWebAuthenticationSession 은
  /// 커스텀 scheme 콜백을 OS 가 직접 가로채 돌려주므로, 예전에 내장 웹뷰에서
  /// 겪은 "흰 화면" 문제 없이 앱 안에서 로그인이 끝난다. 받은 콜백 URL 은
  /// getSessionFromUrl 로 세션 교환하며, 성공하면 authStateChanges 에
  /// signedIn 이벤트가 그대로 흘러가 기존 화면 로직이 동일하게 동작한다.
  Future<bool> signInWithKakao() async {
    final client = _client;
    if (client == null) throw '서버에 연결할 수 없습니다.';
    if (Platform.isIOS) return _signInWithKakaoInApp(client);
    try {
      return await client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: appDeepLinkRedirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      throw _koreanError(e.message);
    } catch (_) {
      throw '카카오 로그인 중 오류가 발생했습니다.';
    }
  }

  Future<bool> _signInWithKakaoInApp(SupabaseClient client) async {
    try {
      final oauth = await client.auth.getOAuthSignInUrl(
        provider: OAuthProvider.kakao,
        redirectTo: appDeepLinkRedirectTo,
      );
      final result = await FlutterWebAuth2.authenticate(
        url: oauth.url,
        callbackUrlScheme: Uri.parse(appDeepLinkRedirectTo).scheme,
      );
      await client.auth.getSessionFromUrl(Uri.parse(result));
      return true;
    } on PlatformException catch (e) {
      // 사용자가 로그인 시트를 닫은 경우: 오류 문구 없이 조용히 종료.
      if (e.code == 'CANCELED') throw const AuthCanceled();
      throw '카카오 로그인 중 오류가 발생했습니다.';
    } on AuthException catch (e) {
      throw _koreanError(e.message);
    } catch (_) {
      throw '카카오 로그인 중 오류가 발생했습니다.';
    }
  }

  /// Apple 로 로그인 (iOS 전용, App Store 가이드라인 4.8 대응).
  /// 네이티브 Apple 로그인 시트에서 받은 identity token 을 Supabase 에
  /// signInWithIdToken 으로 넘긴다. nonce 는 원문을 Supabase 에, SHA-256
  /// 해시를 Apple 에 넘겨야 Supabase 가 토큰 위변조를 검증할 수 있다.
  /// Supabase Dashboard > Authentication > Providers > Apple 이 켜져 있고
  /// Client IDs 에 iOS Bundle ID(com.jumeok.jumeokYori)가 들어가 있어야 한다.
  Future<void> signInWithApple() async {
    final client = _client;
    if (client == null) throw '서버에 연결할 수 없습니다.';
    final rawNonce = client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null) throw 'Apple 로그인 정보를 받지 못했습니다.';
      await client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      // Apple 은 이름을 최초 로그인 때 한 번만 준다. 받았을 때 저장해 둔다.
      final name = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
      if (name.isNotEmpty) {
        await client.auth.updateUser(
          UserAttributes(data: {'display_name': name, 'full_name': name}),
        );
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthCanceled();
      }
      throw 'Apple 로그인 중 오류가 발생했습니다.';
    } on AuthException catch (e) {
      throw _koreanError(e.message);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Apple 로그인 중 오류가 발생했습니다.';
    }
  }

  /// 비밀번호 재설정 메일 전송. 회원가입 인증 메일과 같은 이유로
  /// redirectTo 를 명시한다 (Supabase 기본 Site URL 로 빠지면 404 위험).
  Future<void> resetPassword(String email) async {
    final client = _client;
    if (client == null) throw '서버에 연결할 수 없습니다.';
    try {
      await client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: appDeepLinkRedirectTo,
      );
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
        final email = resolveDisplayEmail(user);
        final meta = user.userMetadata;
        final metaNickname = _metaString(meta, [
          'full_name',
          'name',
          'nickname',
        ]);
        final fallback = Profile(
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
        // 신규 사용자의 프로필만 생성한다. insert를 사용하고 충돌 시
        // 아무 값도 갱신하지 않으므로 기존 role/이름/가게 관계를 덮어쓰지 않는다.
        try {
          await client.from('profiles').insert({
            'id': user.id,
            'email': email,
            'display_name': fallback.displayName,
            'avatar_url': fallback.avatarUrl,
          });
          final created = await client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();
          if (created != null) return Profile.fromJson(created);
        } catch (_) {
          // DB 트리거와 동시에 생성된 경우 또는 RLS로 fallback insert가
          // 거절된 경우에도 정상 세션을 실패 처리하지 않는다.
        }
        return fallback;
      }
      var profile = Profile.fromJson(res);
      final displayEmail = resolveDisplayEmail(
        user,
        profileEmail: profile.email,
      );
      if (profile.email.isEmpty && displayEmail != null) {
        // 표시용 fallback만 메모리에 반영한다. DB의 기존 profile은 갱신하지 않는다.
        profile = profile.copyWith(email: displayEmail);
      }
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

  /// 화면 표시용 이메일 후보를 찾는다. 로그인 성공 여부나 사용자 식별에는
  /// 사용하지 않으며, 어떤 후보도 없으면 null을 그대로 반환한다.
  static String? resolveDisplayEmail(User user, {String? profileEmail}) {
    String? identityEmail;
    for (final identity in user.identities ?? const []) {
      if (identity.provider != 'kakao') continue;
      identityEmail = _nonEmpty(identity.identityData?['email']);
      if (identityEmail != null) break;
    }
    return resolveDisplayEmailCandidates(
      authEmail: user.email,
      metadataEmail: user.userMetadata?['email'],
      identityEmail: identityEmail,
      profileEmail: profileEmail,
    );
  }

  static String? resolveDisplayEmailCandidates({
    Object? authEmail,
    Object? metadataEmail,
    Object? identityEmail,
    Object? profileEmail,
  }) {
    final resolvedAuthEmail = _nonEmpty(authEmail);
    if (resolvedAuthEmail != null) return resolvedAuthEmail;
    final resolvedMetadataEmail = _nonEmpty(metadataEmail);
    if (resolvedMetadataEmail != null) return resolvedMetadataEmail;
    final resolvedIdentityEmail = _nonEmpty(identityEmail);
    if (resolvedIdentityEmail != null) return resolvedIdentityEmail;
    return _nonEmpty(profileEmail);
  }

  static String? _nonEmpty(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

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
