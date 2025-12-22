import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/settings_page.dart';
import 'package:music_player/database_service.dart';
import 'package:music_player/metadata_cleanup_service.dart';
import 'package:music_player/playback_service.dart';
import 'package:music_player/firebase_sync_service.dart';
import 'package:music_player/theme_service.dart';

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
    registerFallbackValue(Color(0xFF000000));
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

    // Default Stubs
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
    when(() => mockTheme.setAutoMode()).thenAnswer((_) async {});
    when(() => mockTheme.setCustomColor(any())).thenAnswer((_) async {});
  });

  testWidgets('Loads and displays settings', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pump(); // init load
    await tester.pumpAndSettle();

    expect(find.text('Filename Format'), findsOneWidget);
    expect(find.text('Artist - Title.mp3'), findsOneWidget);
    expect(find.text('Duração do Crossfade'), findsOneWidget);
  });

  testWidgets('Changes Filename Format', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Artist - Title.mp3'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Title (Artist).mp3').last);
    await tester.pumpAndSettle();

    verify(() => mockDb.saveFilenameFormat(FilenameFormat.titleArtist))
        .called(1);
  });

  testWidgets('Clean Library interaction', (tester) async {
    when(() => mockCleanup.cleanupLibrary()).thenAnswer((_) async => 5);

    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Polir Biblioteca'));
    await tester.pump(); // Start async
    await tester.pump(const Duration(milliseconds: 100)); // Show snackbar
    await tester.pumpAndSettle();

    verify(() => mockCleanup.cleanupLibrary()).called(1);
    expect(find.text('5 músicas foram polidas e organizadas!'), findsOneWidget);
  });

  testWidgets('Age bypass requires confirmation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(find.text('Confirmação'), findsOneWidget);

    await tester.tap(find.text('Confirmo que sou maior de 18'));
    await tester.pumpAndSettle();

    verify(() => mockDb.saveAgeBypass(true)).called(1);
  });

  testWidgets('Sync interactions', (tester) async {
    when(() => mockSync.enableSync()).thenAnswer((_) async => true);
    when(() => mockSync.pullFromCloud()).thenAnswer((_) async => 10);

    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sincronizar Agora'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    verify(() => mockSync.enableSync()).called(1);
    expect(find.text('Sincronização ativada!'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.cloud_download));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    verify(() => mockSync.pullFromCloud()).called(1);
    expect(find.text('10 itens sincronizados!'), findsOneWidget);
  });
}
