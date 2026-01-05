import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// Duplicate mocktail removed
import 'test_helper.dart'; // test_helper
import 'package:music_tag_editor/models/filename_format.dart';
import 'package:music_tag_editor/screens/settings/settings_screen.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/metadata_cleanup_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/firebase_sync_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/auth_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockMetadataCleanupService extends Mock
    implements MetadataCleanupService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockFirebaseSyncService extends Mock implements FirebaseSyncService {}

class MockThemeService extends Mock implements ThemeService {}

// MockAudioPlayer removed

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockDatabaseService mockDb;
  late MockMetadataCleanupService mockCleanup;
  late MockPlaybackService mockPlayback;
  late MockFirebaseSyncService mockSync;
  late MockThemeService mockTheme;
  late MockPlayer mockPlayer;
  late MockAuthService mockAuth;

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
    mockPlayer = MockPlayer();

    mockAuth = MockAuthService();

    DatabaseService.instance = mockDb;
    MetadataCleanupService.instance = mockCleanup;
    PlaybackService.instance = mockPlayback;
    FirebaseSyncService.instance = mockSync;
    ThemeService.instance = mockTheme;
    AuthService.instance = mockAuth;

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

    when(() => mockAuth.isAuthenticated).thenReturn(false);
  });

  void setupViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('Loads and displays settings', (tester) async {
    setupViewport(tester);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const SettingsScreen(),
    ));

    await tester.pump(); // init load
    await tester.pumpAndSettle();

    expect(find.text('Filename Format'), findsOneWidget);
    expect(find.text('Artist - Title.mp3'), findsOneWidget);
    expect(find.text('Duração do Crossfade'), findsOneWidget);
  });

  testWidgets('Changes Filename Format', (tester) async {
    setupViewport(tester);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const SettingsScreen(),
    ));
    await tester.pumpAndSettle();

    final dropdownFinder = find.text('Artist - Title.mp3');
    await tester.ensureVisible(dropdownFinder);
    await tester.pumpAndSettle();

    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    final itemFinder = find.text('Title (Artist).mp3').last;
    await tester.tap(itemFinder);
    await tester.pumpAndSettle();

    verify(() => mockDb.saveFilenameFormat(FilenameFormat.titleArtist))
        .called(1);
  });

  testWidgets('Clean Library interaction', (tester) async {
    setupViewport(tester);
    when(() => mockCleanup.cleanupLibrary()).thenAnswer((_) async => 5);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const SettingsScreen(),
    ));
    await tester.pumpAndSettle();

    final cleanBtn = find.text('Polir Biblioteca');
    await tester.ensureVisible(cleanBtn);
    await tester.pumpAndSettle();

    await tester.tap(cleanBtn);
    await tester.pump(); // Start async
    await tester.pump(const Duration(milliseconds: 100)); // Show snackbar
    await tester.pumpAndSettle();

    verify(() => mockCleanup.cleanupLibrary()).called(1);
    expect(find.text('5 músicas foram polidas e organizadas!'), findsOneWidget);
  });

  testWidgets('Age bypass requires confirmation', (tester) async {
    setupViewport(tester);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const SettingsScreen(),
    ));
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(find.text('Confirmação'), findsOneWidget);

    await tester.tap(find.text('Confirmo que sou maior de 18'));
    await tester.pumpAndSettle();

    verify(() => mockDb.saveAgeBypass(true)).called(1);
  });

  testWidgets('Sync interactions', (tester) async {
    setupViewport(tester);
    when(() => mockAuth.isAuthenticated).thenReturn(true);
    when(() => mockSync.enableSync()).thenAnswer((_) async => true);
    when(() => mockSync.pullFromCloud()).thenAnswer((_) async => 10);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const SettingsScreen(),
    ));
    await tester.pumpAndSettle();

    final syncBtn = find.text('Sincronizar Agora');
    await tester.ensureVisible(syncBtn);
    await tester.pumpAndSettle();

    await tester.tap(syncBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    verify(() => mockSync.enableSync()).called(1);
    expect(find.text('Sincronização ativada!'), findsOneWidget);

    // Clear SnackBar so the next one can appear immediately
    ScaffoldMessenger.of(tester.element(find.byType(SettingsScreen)))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();

    final downloadBtn = find.byIcon(Icons.cloud_download);
    await tester.ensureVisible(downloadBtn);
    await tester.pumpAndSettle();

    await tester.tap(downloadBtn);
    await tester.pump(); // Start
    await tester.pump(const Duration(milliseconds: 100)); // Process await
    await tester.pump(); // Trigger SnackBar
    await tester.pump(const Duration(milliseconds: 100)); // Show it

    verify(() => mockSync.pullFromCloud()).called(1);

    // Check if ANY SnackBar is there
    final snackBarFinder = find.byType(SnackBar);
    expect(snackBarFinder, findsOneWidget);

    final textFinder =
        find.descendant(of: snackBarFinder, matching: find.byType(Text));
    final Text textWidget = tester.widget<Text>(textFinder);
    expect(textWidget.data, '10 itens sincronizados!');

    await tester.pumpAndSettle();
  });
}
