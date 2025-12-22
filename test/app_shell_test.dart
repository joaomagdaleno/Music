import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/app_shell.dart';
import 'package:music_player/playback_service.dart';
import 'package:music_player/connectivity_service.dart';
import 'package:music_player/database_service.dart';
import 'package:music_player/theme_service.dart';
import 'package:music_player/settings_page.dart';
import 'package:music_player/auth_service.dart';
import 'package:music_player/security_service.dart';
import 'package:music_player/dependency_manager.dart';
import 'package:music_player/search_service.dart';
import 'package:music_player/download_service.dart';
import 'package:music_player/search_page.dart';
import 'package:music_player/home_view.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockThemeService extends Mock implements ThemeService {}

class MockAuthService extends Mock implements AuthService {}

class MockSecurityService extends Mock implements SecurityService {}

class MockDependencyManager extends Mock implements DependencyManager {}

class MockSearchService extends Mock implements SearchService {}

class MockDownloadService extends Mock implements DownloadService {}

void main() {
  group('AppShell Widget Tests', () {
    late MockConnectivityService mockConnectivity;
    late MockPlaybackService mockPlayback;
    late MockAudioPlayer mockPlayer;
    late MockDatabaseService mockDb;
    late MockAuthService mockAuth;
    late MockSecurityService mockSecurity;
    late MockDependencyManager mockDeps;
    late MockSearchService mockSearch;
    late MockDownloadService mockDownload;
    late ValueNotifier<bool> isOffline;

    setUp(() {
      mockConnectivity = MockConnectivityService();
      mockPlayback = MockPlaybackService();
      mockPlayer = MockAudioPlayer();
      mockDb = MockDatabaseService();
      mockAuth = MockAuthService();
      mockSecurity = MockSecurityService();
      mockDeps = MockDependencyManager();
      mockSearch = MockSearchService();
      mockDownload = MockDownloadService();
      isOffline = ValueNotifier<bool>(false);

      ConnectivityService.instance = mockConnectivity;
      PlaybackService.instance = mockPlayback;
      DatabaseService.instance = mockDb;
      ThemeService.instance = MockThemeService();
      AuthService.instance = mockAuth;
      SecurityService.instance = mockSecurity;
      DependencyManager.instance = mockDeps;
      SearchService.instance = mockSearch;
      DownloadService.instance = mockDownload;

      when(() => mockConnectivity.isOffline).thenReturn(isOffline);
      when(() => mockPlayback.player).thenReturn(mockPlayer);
      when(() => mockPlayback.currentTrack).thenReturn(null);
      when(() => mockPlayer.playerStateStream).thenAnswer((_) => Stream.value(
            PlayerState(false, ProcessingState.idle),
          ));

      // Mocks for sub-pages
      when(() => mockDb.getTracks()).thenAnswer((_) async => []);
      when(() => mockDb.getTracks(includeVault: any(named: 'includeVault')))
          .thenAnswer((_) async => []);
      when(() => mockDb.getSetting(any())).thenAnswer((_) async => null);
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);
      when(() => mockDb.getGuestHistory()).thenAnswer((_) async => []);
      when(() => mockDb.loadFilenameFormat())
          .thenAnswer((_) async => FilenameFormat.artistTitle);
      when(() => mockDb.getLearningRules()).thenAnswer((_) async => []);
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => []);
      when(() => mockDb.getMostPlayed()).thenAnswer((_) async => []);

      when(() => mockAuth.isAuthenticated).thenReturn(true);

      when(() =>
              mockDeps.ensureDependencies(onProgress: any(named: 'onProgress')))
          .thenAnswer((_) async => Future.value());
    });

    testWidgets('Shows offline banner when offline', (tester) async {
      isOffline.value = true;

      await tester.pumpWidget(const MaterialApp(home: AppShell()));
      await tester.pump();

      expect(find.text('Modo Offline Ativado'), findsOneWidget);
    });

    testWidgets('Navigation switches pages', (tester) async {
      // Ensure mobile-size viewport
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: AppShell()));
      await tester.pumpAndSettle();

      expect(find.byType(HomeView), findsOneWidget);

      // Directly invoke the onTap callback for index 1 (Search)
      final bottomNavBarFinder = find.byType(BottomNavigationBar);
      expect(bottomNavBarFinder, findsOneWidget);

      final bottomNavBar =
          tester.widget<BottomNavigationBar>(bottomNavBarFinder);
      bottomNavBar.onTap?.call(1);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // SearchPage should be present
      expect(find.byType(SearchPage), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Adapts to wide screen (NavigationRail)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: AppShell()));
      await tester.pump();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
