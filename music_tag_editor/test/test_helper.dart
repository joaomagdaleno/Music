import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/security_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/download_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockThemeService extends Mock implements ThemeService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockSecurityService extends Mock implements SecurityService {}

class MockDependencyManager extends Mock implements DependencyManager {}

class MockSearchService extends Mock implements SearchService {}

class MockDownloadService extends Mock implements DownloadService {}

Future<void> setupMusicTestEnvironment() async {
  // Global setup if needed
}

Future<void> setupMusicTest() async {
  // Reset all singletons with mocks or fresh instances
  AuthService.instance = MockAuthService();
  DatabaseService.instance = MockDatabaseService();
  ThemeService.instance = MockThemeService();
  ConnectivityService.instance = MockConnectivityService();
  PlaybackService.instance = MockPlaybackService();
  SecurityService.instance = MockSecurityService();
  DependencyManager.instance = MockDependencyManager();
  SearchService.instance = MockSearchService();
  DownloadService.instance = MockDownloadService();

  // Add common stubs to prevent "Null is not a subtype of Future" errors
  when(() => AuthService.instance.logout()).thenAnswer((_) async {});

  when(() => SecurityService.instance.logout()).thenAnswer((_) async {});
  when(() => SecurityService.instance.init()).thenAnswer((_) async {});

  when(() => ThemeService.instance.init()).thenAnswer((_) async {});
  when(() => ThemeService.instance.setAutoMode()).thenAnswer((_) async {});

  when(() => DatabaseService.instance.initForTesting(any()))
      .thenAnswer((_) async {});

  when(() => DependencyManager.instance.ensureDependencies(
      onProgress: any(named: 'onProgress'))).thenAnswer((_) async {});

  when(() => PlaybackService.instance.init()).thenAnswer((_) async {});
}
