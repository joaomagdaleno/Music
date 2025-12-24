import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/home_view.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';
import 'package:music_tag_editor/services/security_service.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';
import 'package:music_tag_editor/services/desktop_integration_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/firebase_sync_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';
import 'golden_helper.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockThemeService extends Mock implements ThemeService {}

class MockAuthService extends Mock implements AuthService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

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
  group('HomeView Golden Tests', () {
    late MockDatabaseService mockDb;
    late MockPlaybackService mockPlayback;
    late MockThemeService mockTheme;
    late MockAuthService mockAuth;
    late MockConnectivityService mockConnectivity;
    late MockSecurityService mockSecurity;
    late MockEqualizerService mockEqualizer;
    late MockDesktopIntegrationService mockDesktop;
    late MockDependencyManager mockDeps;
    late MockSearchService mockSearch;
    late MockDownloadService mockDownload;
    late MockFirebaseSyncService mockSync;
    late MockLocalDuoService mockDuo;
    late MockLyricsService mockLyrics;

    setUpAll(() async {
      await loadAppFonts();
    });

    setUp(() {
      mockDb = MockDatabaseService();
      mockPlayback = MockPlaybackService();
      mockTheme = MockThemeService();
      mockAuth = MockAuthService();
      mockConnectivity = MockConnectivityService();
      mockSecurity = MockSecurityService();
      mockEqualizer = MockEqualizerService();
      mockDesktop = MockDesktopIntegrationService();
      mockDeps = MockDependencyManager();
      mockSearch = MockSearchService();
      mockDownload = MockDownloadService();
      mockSync = MockFirebaseSyncService();
      mockDuo = MockLocalDuoService();
      mockLyrics = MockLyricsService();

      DatabaseService.instance = mockDb;
      PlaybackService.instance = mockPlayback;
      ThemeService.instance = mockTheme;
      AuthService.instance = mockAuth;
      ConnectivityService.instance = mockConnectivity;
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
      when(() => mockDb.getTracks()).thenAnswer((_) async => [
            {
              'id': '1',
              'title': 'Golden Song',
              'artist': 'Golden Artist',
              'path': '/mock/path/1.mp3',
            },
            {
              'id': '2',
              'title': 'Silver Track',
              'artist': 'Silver Band',
              'path': '/mock/path/2.mp3',
            }
          ]);
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => [
            {
              'id': '1',
              'title': 'Golden Song',
              'artist': 'Golden Artist',
              'imageUrl': 'https://example.com/cover.jpg',
            }
          ]);
      when(() => mockPlayback.currentTrack).thenReturn(null);
      when(() => mockTheme.primaryColor).thenReturn(Colors.blue);
      when(() => mockTheme.customColor).thenReturn(null);
      when(() => mockTheme.useCustomColor).thenReturn(false);

      HttpOverrides.global = MockHttpOverrides();
    });

    tearDown(() {
      HttpOverrides.global = null;
    });

    testGoldens('HomeView initial state', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.tabletLandscape,
        ])
        ..addScenario(
          name: 'initial',
          widget: const HomeView(),
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'home_view_initial');
    });
  });
}
