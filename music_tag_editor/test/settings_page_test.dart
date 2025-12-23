import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_tag_editor/views/settings_page.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/metadata_cleanup_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/firebase_sync_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockMetadataCleanupService extends Mock
    implements MetadataCleanupService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockFirebaseSyncService extends Mock implements FirebaseSyncService {}

class MockThemeService extends Mock implements ThemeService {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late MockDatabaseService mockDb;
  late MockMetadataCleanupService mockCleanup;
  late MockPlaybackService mockPlayback;
  late MockFirebaseSyncService mockSync;
  late MockThemeService mockTheme;
  late MockAudioPlayer mockPlayer;

  setUpAll(() {
    registerFallbackValue(FilenameFormat.artistTitle);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(const Color(0xFF000000));
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockCleanup = MockMetadataCleanupService();
    mockPlayback = MockPlaybackService();
    mockSync = MockFirebaseSyncService();
    mockTheme = MockThemeService();
    mockPlayer = MockAudioPlayer();

    DatabaseService.instance = mockDb;
    MetadataCleanupService.instance = mockCleanup;
    PlaybackService.instance = mockPlayback;
    FirebaseSyncService.instance = mockSync;
    ThemeService.instance = mockTheme;

    when(() => mockDb.loadFilenameFormat())
        .thenAnswer((_) async => FilenameFormat.artistTitle);
    when(() => mockDb.loadCrossfadeDuration()).thenAnswer((_) async => 3);
    when(() => mockDb.loadAgeBypass()).thenAnswer((_) async => false);
    when(() => mockDb.saveFilenameFormat(any())).thenAnswer((_) async {});
    when(() => mockDb.saveCrossfadeDuration(any())).thenAnswer((_) async {});
    when(() => mockDb.saveAgeBypass(any())).thenAnswer((_) async {});

    when(() => mockPlayback.updateCrossfadeDuration(any()))
        .thenAnswer((_) async {});
    when(() => mockPlayback.player).thenReturn(mockPlayer);

    when(() => mockTheme.useCustomColor).thenReturn(false);
    when(() => mockTheme.customColor).thenReturn(const Color(0xFF000000));
    when(() => mockTheme.setAutoMode()).thenAnswer((_) async {});
    when(() => mockTheme.setCustomColor(any())).thenAnswer((_) async {});
  });

  testWidgets('Sync interactions', (tester) async {
    when(() => mockSync.enableSync()).thenAnswer((_) async => true);
    when(() => mockSync.pullFromCloud()).thenAnswer((_) async => 10);

    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    final syncBtn = find.text('Sincronizar Agora');
    await tester.ensureVisible(syncBtn);
    await tester.pumpAndSettle();

    await tester.tap(syncBtn);
    // Use manual pumps to handle the loader
    await tester.pump(); // Show loader
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(); // Hide loader, show snackbar

    expect(find.text('Sincronização ativada!'), findsOneWidget);

    final downloadBtn = find.byIcon(Icons.cloud_download);
    await tester.ensureVisible(downloadBtn);
    await tester.pumpAndSettle();

    await tester.tap(downloadBtn);
    await tester.pump(); // Show loader
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(); // Hide loader, show snackbar

    expect(find.text('10 itens sincronizados!'), findsOneWidget);
  });
}
