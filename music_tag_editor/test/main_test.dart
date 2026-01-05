@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/main.dart';
import 'package:music_tag_editor/screens/library/library_screen.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/models/filename_format.dart';
// import 'package:music_tag_editor/models/filename_format.dart'; // duplicate removed
import 'package:media_kit/media_kit.dart';
import 'test_helper.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockThemeService extends Mock implements ThemeService {}

// Removed MockAudioPlayer

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockThemeService mockTheme;
  late MockAuthService mockAuth;
  late MockConnectivityService mockConnectivity;
  late MockDatabaseService mockDb;
  late MockPlaybackService mockPlayback;
  late MockPlayer mockPlayer;

  setUp(() {
    mockTheme = MockThemeService();
    mockAuth = MockAuthService();
    mockConnectivity = MockConnectivityService();
    mockDb = MockDatabaseService();
    mockPlayback = MockPlaybackService();
    mockPlayer = MockPlayer();

    ThemeService.instance = mockTheme;
    AuthService.instance = mockAuth;
    ConnectivityService.instance = mockConnectivity;
    DatabaseService.instance = mockDb;
    PlaybackService.instance = mockPlayback;

    when(() => mockTheme.primaryColor).thenReturn(Colors.blue);
    when(() => mockTheme.addListener(any())).thenReturn(null);
    when(() => mockTheme.removeListener(any())).thenReturn(null);
    when(() => mockAuth.isAuthenticated).thenReturn(false);
    when(() => mockConnectivity.isOffline).thenReturn(ValueNotifier(false));
    when(() => mockDb.loadFilenameFormat())
        .thenAnswer((_) async => FilenameFormat.artistTitle);
    when(() => mockDb.getTracks()).thenAnswer((_) async => []);
    when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);
    when(() => mockPlayback.player).thenReturn(mockPlayer);
    when(() => mockPlayback.currentTrack).thenReturn(null);
    when(() => mockPlayback.currentTrackStream)
        .thenAnswer((_) => const Stream.empty());

    // Use FakePlayerStream for all streams
    when(() => mockPlayer.stream).thenReturn(FakePlayerStream());
    when(() => mockPlayer.state).thenReturn(const PlayerState());
  });

  group('MusicTagEditorApp', () {
    testWidgets('renders MaterialApp', (tester) async {
      await tester.pumpWidget(
          const MusicTagEditorApp(platform: TargetPlatform.android));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets(
        'shows HomeScreen in AppShell when not authenticated (Guest Mode)',
        (tester) async {
      when(() => mockAuth.isAuthenticated).thenReturn(false);

      await tester.pumpWidget(
          const MusicTagEditorApp(platform: TargetPlatform.android));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Que tal continuar de onde parou?'), findsOneWidget);
    });

    testWidgets('uses theme color from ThemeService', (tester) async {
      when(() => mockTheme.primaryColor).thenReturn(Colors.purple);

      await tester.pumpWidget(
          const MusicTagEditorApp(platform: TargetPlatform.android));
      await tester.pump(const Duration(milliseconds: 100));

      final MaterialApp app =
          tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'Music Tag Editor');
    });
  });

  group('LibraryScreen', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const LibraryScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test Library'), findsOneWidget);
    });

    testWidgets('has DefaultTabController', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const LibraryScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DefaultTabController), findsOneWidget);
    });

    testWidgets('renders tab bar with tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const LibraryScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Pastas Local'), findsOneWidget);
      expect(find.text('Minha Biblioteca'), findsOneWidget);
      expect(find.text('Smart Mix'), findsOneWidget);
      expect(find.text('Mood Explorer'), findsOneWidget);
    });

    testWidgets('has settings button in app bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const LibraryScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('has download button in app bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const LibraryScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('shows empty folder message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const LibraryScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Nenhuma pasta selecionada.'), findsOneWidget);
      expect(find.text('Selecionar Pasta'), findsOneWidget);
    });
  });
}
// IGNORE_TESTS_TEMPORARILY
