import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/login_page.dart';
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/security_service.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';
import 'package:music_tag_editor/services/desktop_integration_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/firebase_sync_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockThemeService extends Mock implements ThemeService {}

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
  group('LoginPage Golden Tests', () {
    late MockAuthService mockAuth;
    late MockConnectivityService mockConnectivity;
    late MockPlaybackService mockPlayback;
    late MockDatabaseService mockDb;
    late MockThemeService mockTheme;
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
      mockAuth = MockAuthService();
      mockConnectivity = MockConnectivityService();
      mockPlayback = MockPlaybackService();
      mockDb = MockDatabaseService();
      mockTheme = MockThemeService();
      mockSecurity = MockSecurityService();
      mockEqualizer = MockEqualizerService();
      mockDesktop = MockDesktopIntegrationService();
      mockDeps = MockDependencyManager();
      mockSearch = MockSearchService();
      mockDownload = MockDownloadService();
      mockSync = MockFirebaseSyncService();
      mockDuo = MockLocalDuoService();
      mockLyrics = MockLyricsService();

      AuthService.instance = mockAuth;
      ConnectivityService.instance = mockConnectivity;
      PlaybackService.instance = mockPlayback;
      DatabaseService.instance = mockDb;
      ThemeService.instance = mockTheme;
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
    });

    testGoldens('LoginPage initial state', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
          Device.tabletLandscape,
        ])
        ..addScenario(
          name: 'initial',
          widget: const LoginPage(),
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'login_page_initial');
    });

    testGoldens('LoginPage register mode', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
        ])
        ..addScenario(
          name: 'register_mode',
          widget: const LoginPage(),
        );

      await tester.pumpDeviceBuilder(builder);

      // Toggle to register mode
      await tester.tap(find.textContaining('Não tem conta?'));
      await tester.pump();

      await screenMatchesGolden(tester, 'login_page_register');
    });
  });
}
