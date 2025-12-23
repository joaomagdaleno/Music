import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/vault_view.dart';
import 'package:music_tag_editor/services/security_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart'; // For SearchResult

class MockSecurityService extends Mock implements SecurityService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockPlaybackService extends Mock implements PlaybackService {}

void main() {
  late MockSecurityService mockSecurity;
  late MockDatabaseService mockDb;
  late MockPlaybackService mockPlayback;

  setUpAll(() {
    registerFallbackValue(SearchResult(
        id: '0',
        title: 'fallback',
        artist: 'fallback',
        url: 'url',
        platform: MediaPlatform.unknown));
  });

  setUp(() {
    mockSecurity = MockSecurityService();
    mockDb = MockDatabaseService();
    mockPlayback = MockPlaybackService();

    SecurityService.instance = mockSecurity;
    DatabaseService.instance = mockDb;
    PlaybackService.instance = mockPlayback;

    when(() => mockSecurity.unlockVault(any())).thenAnswer((_) async => true);
    when(() => mockSecurity.setupVaultPassword(any())).thenAnswer((_) async {});
    when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);
    when(() => mockDb.toggleVault(any(), any())).thenAnswer((_) async {});
  });

  Widget createTestWidget() {
    return const MaterialApp(home: VaultView());
  }

  group('VaultView', () {
    testWidgets('renders locked state', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Cofre Privado'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('has password field', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Senha do Cofre'), findsOneWidget);
    });

    testWidgets('has unlock button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Desbloquear'), findsOneWidget);
    });

    testWidgets('calls unlockVault on button press', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'password');
      await tester.tap(find.text('Desbloquear'));
      await tester.pump(); // Start async _unlock
      await tester.pump(); // Finish async and rebuild

      verify(() => mockSecurity.unlockVault('password')).called(1);
    });
  });
}
