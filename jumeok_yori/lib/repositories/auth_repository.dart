import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

/// AuthService 를 감싸 프로필까지 함께 다루는 repository
class AuthRepository {
  final AuthService _authService = AuthService();

  bool get isAvailable => _authService.isAvailable;

  User? get currentUser => _authService.getCurrentUser();

  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  Future<void> signUp(String email, String password,
          {String? displayName}) =>
      _authService.signUp(email, password, displayName: displayName);

  Future<void> signIn(String email, String password) =>
      _authService.signIn(email, password);

  Future<void> resetPassword(String email) =>
      _authService.resetPassword(email);

  Future<void> signOut() => _authService.signOut();

  Future<Profile?> fetchProfile() => _authService.getCurrentProfile();
}
