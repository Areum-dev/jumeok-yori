import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_state.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/kakao_login_button.dart';
import '../widgets/logo_widget.dart';
import '../widgets/primary_button.dart';
import 'terms_agreement_screen.dart';

enum _AuthMode { login, signup, emailSent }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authRepo = AuthRepository();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _loading = false;
  bool _kakaoLoading = false;
  bool _obscure = true;
  String? _error;
  bool _marketingAgreed = false;

  // 카카오 로그인은 브라우저 복귀 후 비동기로 완료되므로, signInWithOAuth 의
  // 반환값이 아니라 인증 상태 스트림으로 완료 여부를 감지한다. 이 화면에서만
  // 구독하고(다른 화면에서 중복 구독하지 않음) dispose 시 반드시 해제한다.
  StreamSubscription<AuthState>? _authStateSub;
  // 이메일 로그인(직접 흐름)과 스트림 이벤트가 같은 로그인 건에 대해
  // 동시에 _afterLogin 을 호출해 화면 이동이 중복 발생하지 않도록 방지.
  bool _navigatedAfterLogin = false;

  // 카카오 버튼을 누른 뒤 실제로 카카오 identity 가 생긴 signedIn 이벤트만
  // "카카오 로그인 성공"으로 인정하기 위한 상태. 흰 화면을 닫고 돌아왔을 때
  // 기존에 남아있던 이메일 세션(또는 스트림이 재전달하는 과거 세션)을
  // 새 카카오 로그인 성공으로 착각해 홈으로 이동시키지 않기 위함이다.
  bool _kakaoLoginPending = false;
  String? _userIdBeforeKakaoLogin;

  /// signedIn 이벤트의 세션이 실제 카카오 로그인 결과인지 판별한다.
  /// identities 목록에 provider == 'kakao' 가 있거나, app_metadata 의
  /// provider/providers 가 kakao 를 가리키면 카카오 로그인으로 간주한다.
  bool _isKakaoSession(Session? session) {
    final user = session?.user;
    if (user == null) return false;
    final hasKakaoIdentity =
        user.identities?.any((i) => i.provider == 'kakao') ?? false;
    if (hasKakaoIdentity) return true;
    final metaProvider = user.appMetadata['provider'];
    if (metaProvider == 'kakao') return true;
    final metaProviders = user.appMetadata['providers'];
    if (metaProviders is List && metaProviders.contains('kakao')) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _authStateSub = _authRepo.authStateChanges.listen(
      (state) {
        if (state.event != AuthChangeEvent.signedIn) return;
        if (_kakaoLoginPending) {
          // 카카오 로그인 진행 중에 받은 signedIn 이벤트: 실제로 카카오
          // identity 가 생긴 세션인지 확인한 경우에만 성공으로 처리한다.
          // (user id 가 로그인 시작 전과 같은지는 참고 로그로만 남긴다 -
          // Supabase 가 기존 이메일 계정에 카카오 identity 를 자동으로
          // 연결하는 케이스에서는 id 가 그대로일 수 있으므로, id 변경
          // 여부를 성공/실패 판정의 필수 조건으로 삼지 않는다.)
          final isKakao = _isKakaoSession(state.session);
          final newUserId = state.session?.user.id;
          if (!isKakao) {
            debugPrint(
              '[AUTH] 카카오 로그인 대기 중 signedIn 이벤트를 받았지만 kakao '
              'identity 가 없어 무시함 (before=$_userIdBeforeKakaoLogin, '
              'event user=$newUserId) - 기존 세션을 카카오 성공으로 오인하지 않음',
            );
            return;
          }
          debugPrint(
            '[AUTH] 카카오 로그인 성공 확인 (before=$_userIdBeforeKakaoLogin, '
            'after=$newUserId)',
          );
          _kakaoLoginPending = false;
          _userIdBeforeKakaoLogin = null;
          _afterLogin();
          return;
        }
        // 카카오 로그인 대기 중이 아닌 signedIn 은 이메일 로그인 직접 흐름과
        // 겹쳐서 오는 경우다. _afterLogin 자체가 중복 호출을 막아준다.
        _afterLogin();
      },
      // 카카오 로그인 후 앱으로 복귀하는 딥링크 처리 중 세션 교환이 실패하면
      // (예: redirect 오류, 네트워크 오류) supabase_flutter 가 이 스트림에
      // 에러를 흘려보낸다. 핸들러가 없으면 처리되지 않은 비동기 예외가 되므로
      // 반드시 잡아서 내부 오류 내용은 로그로만 남기고 사용자에게는
      // 안전한 한국어 메시지만 보여준다.
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[AUTH] 로그인 세션 처리 중 오류: $error');
        if (mounted) {
          setState(() => _error = '로그인 처리 중 오류가 발생했어요. 다시 시도해 주세요.');
        }
      },
    );
  }

  @override
  void dispose() {
    _authStateSub?.cancel();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  String _koreanError(String message) {
    if (message.contains('Email not confirmed')) {
      return '이메일 인증을 완료한 뒤 로그인해 주세요.';
    }
    if (message.contains('Invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않아요.';
    }
    if (message.contains('Email already registered') ||
        message.contains('already registered')) {
      return '이미 가입된 이메일이에요.';
    }
    if (message.contains('Password should be')) {
      return '비밀번호는 6자 이상이어야 해요.';
    }
    if (message.contains('Unable to validate email')) {
      return '올바른 이메일 형식이 아니에요.';
    }
    if (message.contains('network') || message.contains('Network')) {
      return '네트워크 연결을 확인해 주세요.';
    }
    return '오류가 발생했어요. 다시 시도해 주세요.';
  }

  /// AuthService 는 이미 한국어 메시지를 throw 하므로, 그대로 쓰되
  /// 영문 메시지가 올라온 경우를 대비해 한 번 더 변환합니다.
  String _mapError(Object e) {
    final raw = e.toString().replaceFirst('Exception: ', '');
    if (RegExp(r'[가-힣]').hasMatch(raw)) return raw;
    return _koreanError(raw);
  }

  Future<void> _afterLogin() async {
    // 이메일 로그인의 직접 호출과 authStateChanges 스트림(카카오 OAuth 완료,
    // 그리고 이메일 로그인 시에도 동일 이벤트가 한 번 더 발생함)이 겹쳐
    // 같은 로그인 건에 대해 두 번 실행/이동하지 않도록 가드.
    if (_navigatedAfterLogin) return;
    _navigatedAfterLogin = true;
    if (!mounted) return;

    // 카카오 계정이 이메일 제공에 동의하지 않은 경우 user.email 이 없을 수 있다.
    // 가짜 이메일을 만들거나 기존 계정과 임의로 연결하지 않고, 그대로 진행하되
    // 사용자에게 한 번 안내만 한다 (Supabase의 "Allow users without an email"
    // 설정이 켜져 있다는 전제 — 꺼져 있다면애초에 이 경로까지 오지 못하고
    // Supabase 쪽에서 계정 생성 자체가 실패함).
    final currentEmail = Supabase.instance.client.auth.currentUser?.email;
    if (currentEmail == null || currentEmail.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('이메일 정보 없음'),
          content: const Text(
            '카카오 계정에 이메일 제공 동의가 없어 이메일 없이 로그인됐어요.\n'
            '비밀번호 재설정 등 이메일이 필요한 기능은 사용할 수 없어요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      if (!mounted) return;
    }

    final appState = context.read<AppState>();
    await appState.refreshProfile();
    await appState.loadSaved();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _signInWithKakao() async {
    if (_kakaoLoading || _loading) return; // 중복 클릭 방지
    // 기존 이메일 세션이 있어도 여기서 signOut 하지 않는다. 대신 로그인
    // 시작 전 사용자 id 를 기록해두고, 이후 signedIn 이벤트가 실제로
    // "새로운" 카카오 사용자로 바뀐 것인지 판별하는 데 참고용으로 남긴다.
    _userIdBeforeKakaoLogin = Supabase.instance.client.auth.currentUser?.id;
    setState(() {
      _kakaoLoading = true;
      _kakaoLoginPending = true;
      _error = null;
    });
    try {
      // signInWithOAuth 는 "카카오 로그인 페이지를 여는 데 성공했는지"만 반환한다.
      // 실제 로그인 완료는 initState 에서 구독한 authStateChanges 스트림이
      // signedIn 이벤트를 받고, 그 세션이 실제 카카오 identity 를 가질 때만
      // _afterLogin 이 호출된다 (_isKakaoSession 참고).
      final launched = await _authRepo.signInWithKakao();
      if (!launched && mounted) {
        _kakaoLoginPending = false;
        setState(() => _error = '카카오 로그인 화면을 열지 못했어요. 다시 시도해 주세요.');
      }
    } catch (e) {
      _kakaoLoginPending = false;
      if (mounted) setState(() => _error = _mapError(e));
    } finally {
      // 브라우저로 전환된 뒤에는 로딩 표시를 계속 띄워둘 필요가 없다
      // (사용자가 로그인을 취소하고 앱으로 돌아와도 화면이 멈춰있지 않도록).
      // _kakaoLoginPending 은 여기서 끄지 않는다 - 브라우저가 열린 뒤에도
      // 실제 로그인 결과(딥링크 복귀)는 비동기로 나중에 도착하기 때문이다.
      if (mounted) setState(() => _kakaoLoading = false);
    }
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text;
    if (email.isEmpty || !email.contains('@') || pw.isEmpty) {
      setState(() => _error = '이메일과 비밀번호를 입력해 주세요.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authRepo.signIn(email, pw);
      await _afterLogin();
    } catch (e) {
      setState(() => _error = _mapError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text;
    final pw2 = _pw2Ctrl.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = '올바른 이메일을 입력해 주세요.');
      return;
    }
    if (pw.length < 6) {
      setState(() => _error = '비밀번호는 6자 이상이어야 해요.');
      return;
    }
    if (pw != pw2) {
      setState(() => _error = '비밀번호가 일치하지 않아요.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authRepo.signUp(email, pw);
      // 마케팅 수신 동의 여부를 profiles에 저장 (실패해도 무시)
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client.from('profiles').upsert({
            'id': userId,
            'marketing_agreed': _marketingAgreed,
          });
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() => _mode = _AuthMode.emailSent);
    } catch (e) {
      setState(() => _error = _mapError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = '비밀번호를 재설정할 이메일을 입력해 주세요.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authRepo.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호 재설정 메일을 보냈어요.')));
    } catch (e) {
      setState(() => _error = _mapError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _continueAsGuest() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  /// 회원가입 모드로 전환 전 약관 동의 화면을 먼저 표시합니다.
  Future<void> _goToSignup() async {
    final result = await Navigator.push<Map<String, bool>>(
      context,
      MaterialPageRoute(builder: (_) => const TermsAgreementScreen()),
    );
    if (!mounted) return;
    if (result == null) return; // 동의 취소
    setState(() {
      _marketingAgreed = result['marketing'] ?? false;
      _mode = _AuthMode.signup;
      _error = null;
      _pwCtrl.clear();
      _pw2Ctrl.clear();
    });
  }

  void _toggleMode() {
    if (_mode == _AuthMode.login) {
      _goToSignup();
      return;
    }
    setState(() {
      _mode = _AuthMode.login;
      _error = null;
      _marketingAgreed = false;
      _pwCtrl.clear();
      _pw2Ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == _AuthMode.emailSent) return _emailSentScreen();

    final isSignup = _mode == _AuthMode.signup;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: LogoWidget(size: 72, showText: true)),
              const SizedBox(height: 8),
              const Text(
                '고민 끝. 오늘은 이거.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textGray),
              ),
              const SizedBox(height: 20),
              Text(
                isSignup ? '회원가입' : '로그인',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkInk,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pwCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (isSignup) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _pw2Ctrl,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 확인',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: isSignup ? '회원가입' : '로그인',
                isLoading: _loading,
                onPressed: isSignup ? _signUp : _signIn,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading ? null : _toggleMode,
                child: Text(
                  isSignup ? '이미 계정이 있어요' : '회원가입하기',
                  style: const TextStyle(color: AppColors.orange),
                ),
              ),
              if (!isSignup)
                TextButton(
                  onPressed: _loading ? null : _resetPassword,
                  child: const Text(
                    '비밀번호를 잊으셨나요?',
                    style: TextStyle(color: AppColors.textGray),
                  ),
                ),
              if (!isSignup) ...[
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Expanded(child: Divider(color: AppColors.softGray)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '또는',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.softGray)),
                  ],
                ),
                const SizedBox(height: 12),
                KakaoLoginButton(
                  isLoading: _kakaoLoading,
                  onPressed: _signInWithKakao,
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _loading ? null : _continueAsGuest,
                child: const Text('게스트로 시작'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailSentScreen() => Scaffold(
    backgroundColor: AppColors.ivory,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✉️', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 24),
            const Text(
              '인증 메일을 보냈어요.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '${_emailCtrl.text}\n메일함에서 인증을 완료한 뒤\n로그인해 주세요.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textGray,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _mode = _AuthMode.login;
                  _error = null;
                  _pwCtrl.clear();
                  _pw2Ctrl.clear();
                }),
                child: const Text('로그인 화면으로'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
