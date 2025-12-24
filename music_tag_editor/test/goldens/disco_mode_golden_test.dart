import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alchemist/alchemist.dart';
import 'package:mocktail/mocktail.dart';
import 'golden_helper.dart';
import 'package:music_tag_editor/views/disco_mode_view.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart'; // For SearchResult
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/security_service.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';
import 'package:music_tag_editor/services/desktop_integration_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/firebase_sync_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';

class MockPlaybackService extends Mock implements PlaybackService {}

class MockThemeService extends Mock implements ThemeService {}

class MockAuthService extends Mock implements AuthService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockSecurityService extends Mock implements SecurityService {}

class MockEqualizerService extends Mock implements EqualizerService {}

class MockDesktopIntegrationService extends Mock
    implements DesktopIntegrationService {}

class MockDependencyManager extends Mock implements DependencyManager {}

class MockSearchService extends Mock implements SearchService {}

class MockDownloadService extends Mock implements DownloadService {}

class MockFirebaseSyncService extends Mock implements FirebaseSyncService {}

class MockLocalDuoService extends Mock implements LocalDuoService {}

class MockLyricsService extends Mock implements LyricsService {}

void main() {
  group('DiscoModeView Golden Tests', () {
    late MockPlaybackService mockPlayback;
    late MockThemeService mockTheme;
    late MockAuthService mockAuth;
    late MockConnectivityService mockConnectivity;
    late MockDatabaseService mockDb;
    late MockSecurityService mockSecurity;
    late MockEqualizerService mockEqualizer;
    late MockDesktopIntegrationService mockDesktop;
    late MockDependencyManager mockDeps;
    late MockSearchService mockSearch;
    late MockDownloadService mockDownload;
    late MockFirebaseSyncService mockSync;
    late MockLocalDuoService mockDuo;
    late MockLyricsService mockLyrics;

    setUp(() {
      mockPlayback = MockPlaybackService();
      mockTheme = MockThemeService();
      mockAuth = MockAuthService();
      mockConnectivity = MockConnectivityService();
      mockDb = MockDatabaseService();
      mockSecurity = MockSecurityService();
      mockEqualizer = MockEqualizerService();
      mockDesktop = MockDesktopIntegrationService();
      mockDeps = MockDependencyManager();
      mockSearch = MockSearchService();
      mockDownload = MockDownloadService();
      mockSync = MockFirebaseSyncService();
      mockDuo = MockLocalDuoService();
      mockLyrics = MockLyricsService();

      PlaybackService.instance = mockPlayback;
      ThemeService.instance = mockTheme;
      AuthService.instance = mockAuth;
      ConnectivityService.instance = mockConnectivity;
      DatabaseService.instance = mockDb;
      SecurityService.instance = mockSecurity;
      EqualizerService.instance = mockEqualizer;
      DesktopIntegrationService.instance = mockDesktop;
      DependencyManager.instance = mockDeps;
      SearchService.instance = mockSearch;
      DownloadService.instance = mockDownload;
      FirebaseSyncService.instance = mockSync;
      LocalDuoService.instance = mockDuo;
      LyricsService.instance = mockLyrics;

      final isOffline = ValueNotifier<bool>(false);
      when(() => mockConnectivity.isOffline).thenReturn(isOffline);
      when(() => mockDuo.role).thenReturn(DuoRole.none);
      when(() => mockPlayback.currentTrack).thenReturn(SearchResult(
        id: '1',
        title: 'Disco Party',
        artist: 'Flashy Artist',
        url: 'https://example.com/disco.mp3',
        platform: MediaPlatform.unknown,
      ));
      when(() => mockTheme.primaryColor).thenReturn(Colors.purple);
      when(() => mockTheme.customColor).thenReturn(null);
      when(() => mockTheme.useCustomColor).thenReturn(false);

      HttpOverrides.global = MockHttpOverrides();
    });

    tearDown(() {
      HttpOverrides.global = null;
    });

    goldenTest(
      'DiscoModeView initial state',
      fileName: 'disco_mode_view_initial',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'phone',
            constraints: const BoxConstraints(maxWidth: 375, maxHeight: 1500),
            child: const DiscoModeView(),
          ),
        ],
      ),
      pumpBeforeTest: (tester) async {
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
