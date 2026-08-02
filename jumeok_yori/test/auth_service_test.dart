import 'package:flutter_test/flutter_test.dart';
import 'package:jumeok_yori/services/auth_service.dart';

void main() {
  group('카카오 표시 이메일 fallback', () {
    test('auth 이메일을 가장 먼저 사용한다', () {
      expect(
        AuthService.resolveDisplayEmailCandidates(
          authEmail: 'auth@example.com',
          metadataEmail: 'metadata@example.com',
          identityEmail: 'identity@example.com',
          profileEmail: 'profile@example.com',
        ),
        'auth@example.com',
      );
    });

    test('metadata와 identity 및 profile 순서로 fallback한다', () {
      expect(
        AuthService.resolveDisplayEmailCandidates(
          metadataEmail: 'metadata@example.com',
          identityEmail: 'identity@example.com',
          profileEmail: 'profile@example.com',
        ),
        'metadata@example.com',
      );
      expect(
        AuthService.resolveDisplayEmailCandidates(
          identityEmail: 'identity@example.com',
          profileEmail: 'profile@example.com',
        ),
        'identity@example.com',
      );
      expect(
        AuthService.resolveDisplayEmailCandidates(
          profileEmail: 'profile@example.com',
        ),
        'profile@example.com',
      );
    });

    test('모든 후보가 없거나 비어 있으면 null을 유지한다', () {
      expect(
        AuthService.resolveDisplayEmailCandidates(
          authEmail: '',
          metadataEmail: '   ',
        ),
        isNull,
      );
    });
  });
}
