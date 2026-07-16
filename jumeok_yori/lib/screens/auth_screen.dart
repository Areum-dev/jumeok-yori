import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_state.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_theme.dart';
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
  bool _obscure = true;
  String? _error;
  bool _marketingAgreed = false;

  @override
  void dispose() {
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
    if (!mounted) return;
    final appState = context.read<AppState>();
    await appState.refreshProfile();
    await appState.loadSaved();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 재설정 메일을 보냈어요.')),
      );
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
              const Center(
                child: LogoWidget(size: 72, showText: true),
              ),
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
                    icon: Icon(_obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
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
                const Text('인증 메일을 보냈어요.',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(
                  '${_emailCtrl.text}\n메일함에서 인증을 완료한 뒤\n로그인해 주세요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textGray, height: 1.6),
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
