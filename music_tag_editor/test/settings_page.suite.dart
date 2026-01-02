@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/models/filename_format.dart';
import 'package:music_tag_editor/screens/settings/settings_screen.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/services/firebase_sync_service.dart';
import 'package:music_tag_editor/services/metadata_cleanup_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockThemeService extends Mock implements ThemeService {}

class MockAuthService extends Mock implements AuthService {}

class MockFirebaseSyncService extends Mock implements FirebaseSyncService {}

class MockMetadataCleanupService extends Mock
    implements MetadataCleanupService {}

class MockPlaybackService extends Mock implements PlaybackService {}

void main() {
  late MockDatabaseService mockDb;
  late MockThemeService mockTheme;
  late MockAuthService mockAuth;
  late MockFirebaseSyncService mockSync;
  late MockMetadataCleanupService mockCleanup;
  late MockPlaybackService mockPlayback;

  setUp(() {
    mockDb = MockDatabaseService();
    mockTheme = MockThemeService();
    mockAuth = MockAuthService();
    mockSync = MockFirebaseSyncService();
    mockCleanup = MockMetadataCleanupService();
    mockPlayback = MockPlaybackService();

    DatabaseService.instance = mockDb;
    ThemeService.instance = mockTheme;
    AuthService.instance = mockAuth;
    FirebaseSyncService.instance = mockSync;
    MetadataCleanupService.instance = mockCleanup;
    PlaybackService.instance = mockPlayback;

    when(() => mockTheme.primaryColor).thenReturn(Colors.blue);
    when(() => mockTheme.useCustomColor).thenReturn(false);
    when(() => mockTheme.customColor).thenReturn(null);
    when(() => mockTheme.addListener(any())).thenReturn(null);
    when(() => mockTheme.removeListener(any())).thenReturn(null);
    when(() => mockAuth.isAuthenticated).thenReturn(false);

    // Fix: Return enum value, not instance
    when(() => mockDb.loadFilenameFormat())
        .thenAnswer((_) async => FilenameFormat.artistTitle);

    when(() => mockDb.loadCrossfadeDuration()).thenAnswer((_) async => 3);
    when(() => mockDb.loadAgeBypass()).thenAnswer((_) async => false);
    when(() => mockDb.getSpotifyCredentials())
        .thenAnswer((_) async => {'clientId': null, 'clientSecret': null});
  });

  Widget createTestWidget() {
    return MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const SettingsScreen(),
    );
  }

  group('SettingsScreen', () {
    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Start loading
      await tester.pump(); // Finish loading (if fast) or show loader

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('loads settings on init', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      verify(() => mockDb.loadFilenameFormat()).called(1);
    });
  });
}
