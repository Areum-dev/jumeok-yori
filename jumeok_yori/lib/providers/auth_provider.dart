import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../repositories/auth_repository.dart';

/// 인증 상태를 단독으로 관리하는 provider (선택적 사용).
/// 주 상태는 AppState.currentProfile 에 보관되지만,
/// 로그인/회원가입 화면에서 직접 호출할 때 사용합니다.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  bool get isAvailable => _repo.isAvailable;

  Profile? profile;
  bool isBusy = false;
  String? errorMessage;

  Future<bool> signIn(String email, String password) async {
    return _run(() => _repo.signIn(email, password));
  }

  Future<bool> signUp(
    String email,
    String password, {
    String? displayName,
  }) async {
    return _run(() => _repo.signUp(email, password, displayName: displayName));
  }

  Future<void> loadProfile() async {
    profile = await _repo.fetchProfile();
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      await loadProfile();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
