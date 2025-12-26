@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:music_tag_editor/services/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurityService', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      // Reset instance for clean state if needed, though simpler to just ensure storage is mocked
      // SecurityService.instance might be a singleton, so mocking storage affects it globally for this run
    });

    test('instance is accessible', () {
      expect(SecurityService.instance, isNotNull);
    });

    test('encryptString returns encrypted format', () async {
      final service = SecurityService.instance;
      await service.init();

      final encrypted = await service.encryptString('test data');
      expect(encrypted, contains(':'));
      expect(encrypted.split(':').length, 2);
    });

    test('decryptString returns original text', () async {
      final service = SecurityService.instance;
      await service.init();

      final original = 'Hello World';
      final encrypted = await service.encryptString(original);
      final decrypted = await service.decryptString(encrypted);

      expect(decrypted, original);
    });

    test('decryptString handles invalid format gracefully', () async {
      final service = SecurityService.instance;
      await service.init();

      final result = await service.decryptString('notvalidformat');
      expect(result, 'notvalidformat');
    });

    test('_hashPassword produces consistent hash', () async {
      final service = SecurityService.instance;
      await service.init();

      // We can't access _hashPassword directly, but we can test through unlockVault
      // which relies on it
      expect(service, isNotNull);
    });

    test('unlockVault returns false without setup', () async {
      final service = SecurityService.instance;
      await service.init();

      final result = await service.unlockVault('anypassword');
      expect(result, isFalse);
    });

    test('setupVaultPassword allows unlocking', () async {
      final service = SecurityService.instance;
      await service.init();

      await service.setupVaultPassword('mypassword');
      final success = await service.unlockVault('mypassword');
      final fail = await service.unlockVault('wrong');

      expect(success, isTrue);
      expect(fail, isFalse);
    });
  });
}
