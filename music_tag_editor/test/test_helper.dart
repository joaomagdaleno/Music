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
import 'package:music_tag_editor/services/lyrics_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';
import 'package:music_tag_editor/services/firebase_sync_service.dart';
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
