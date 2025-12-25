import 'package:mocktail/mocktail.dart';
import '../lib/services/auth_service.dart';
import '../lib/services/database_service.dart';
import '../lib/services/theme_service.dart';
import '../lib/services/connectivity_service.dart';
import '../lib/services/playback_service.dart';
import '../lib/services/security_service.dart';
import '../lib/services/dependency_manager.dart';
import '../lib/services/search_service.dart';
import '../lib/services/download_service.dart';
import '../lib/services/lyrics_service.dart';
import '../lib/services/local_duo_service.dart';
import '../lib/services/equalizer_service.dart';
import '../lib/services/firebase_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockAuthService extends Mock implements AuthService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockThemeService extends Mock implements ThemeService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockSecurityService extends Mock implements SecurityService {}

class MockDependencyManager extends Mock implements DependencyManager {}

class MockSearchService extends Mock implements SearchService {}

class MockDownloadService extends Mock implements DownloadService {}

class MockLyricsService extends Mock implements LyricsService {}

class MockLocalDuoService extends Mock implements LocalDuoService {}

class MockEqualizerService extends Mock implements EqualizerService {}

class MockFirebaseSyncService extends Mock implements FirebaseSyncService {}

Future<void> setupMusicTest() async {
  // Initialize SQLite FFI once
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Reset ALL core singletons to their REAL internal state
  AuthService.resetInstance();
  DatabaseService.resetInstance();
  ThemeService.resetInstance();
  ConnectivityService.resetInstance();
  PlaybackService.resetInstance();
  SecurityService.resetInstance();
  DependencyManager.resetInstance();
  SearchService.resetInstance();
  DownloadService.resetInstance();
  EqualizerService.resetInstance();
  LyricsService.resetInstance();
  LocalDuoService.resetInstance();
  FirebaseSyncService.resetInstance();

  // Register common fakes only once
  if (!_registerFallbackValueWasCalled) {
    registerFallbackValue(Uri.parse('http://test.com'));
    registerFallbackValue(const Color(0xFF000000));
    _registerFallbackValueWasCalled = true;
  }
}

bool _registerFallbackValueWasCalled = false;
