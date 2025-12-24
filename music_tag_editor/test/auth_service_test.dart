@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_tag_editor/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  bool isAuthenticated = false;

  @override
  User? get user => null;
}

void main() {
  group('AuthService', () {
    late MockAuthService mockAuth;

    setUp(() {
      mockAuth = MockAuthService();
      AuthService.instance = mockAuth;

      when(() => mockAuth.init()).thenAnswer((_) async {});
      when(() => mockAuth.login(any(), any())).thenAnswer((_) async => true);
      when(() => mockAuth.logout()).thenAnswer((_) async {});
      when(() => mockAuth.register(any(), any())).thenAnswer((_) async => true);
    });

    test('instance is accessible', () {
      expect(AuthService.instance, isNotNull);
    });

    test('isAuthenticated returns bool', () {
      expect(mockAuth.isAuthenticated, isFalse);
    });

    test('login returns bool', () async {
      final result = await mockAuth.login('test@email.com', 'password');
      expect(result, isTrue);
    });

    test('register returns bool', () async {
      final result = await mockAuth.register('test@email.com', 'password');
      expect(result, isTrue);
    });

    test('logout completes without error', () async {
      await expectLater(mockAuth.logout(), completes);
    });
  });
}
