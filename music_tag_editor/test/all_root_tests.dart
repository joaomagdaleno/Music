/// Consolidated root tests for Music - reduces startup overhead
/// This covers service tests that were placed in the root directory
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'dart:ui';

import 'auth_service_test.dart' as auth;
import 'backup_service_test.dart' as backup;
import 'connectivity_service_test.dart' as connectivity;
import 'database_service_test.dart' as database;
import 'dependency_manager_test.dart' as dependency;
import 'equalizer_service_test.dart' as equalizer;
import 'firebase_sync_service_test.dart' as firebase_sync;
import 'local_duo_service_test.dart' as local_duo;
import 'lyrics_service_test.dart' as lyrics;
import 'metadata_aggregator_service_test.dart' as metadata_agg;
import 'metadata_cleanup_service_test.dart' as metadata_clean;
import 'metadata_service_test.dart' as metadata;
import 'persona_service_test.dart' as persona;
import 'playback_service_test.dart' as playback;
import 'search_service_test.dart' as search;
import 'security_service_test.dart' as security;
import 'theme_service_test.dart' as theme;

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
import 'package:music_tag_editor/services/firebase_sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockDatabaseService extends Mock implements DatabaseService {}

Future<void> _setupMusicTest() async {
  AuthService.resetInstance();
  DatabaseService.resetInstance();
  ThemeService.resetInstance();
  ConnectivityService.resetInstance();
  PlaybackService.resetInstance();
  SecurityService.resetInstance();
  DependencyManager.resetInstance();
  SearchService.resetInstance();
  DownloadService.resetInstance();
  FirebaseSyncService.resetInstance();

  // Inject mocks to prevent Firebase initialization errors
  FirebaseSyncService.instance.setDependencies(
    auth: MockFirebaseAuth(),
    firestore: MockFirebaseFirestore(),
    db: MockDatabaseService(),
  );

  if (!_registerGuard) {
    registerFallbackValue(Uri.parse('http://test.com'));
    registerFallbackValue(const Color(0xFF000000));
    registerFallbackValue(<String, dynamic>{});
    _registerGuard = true;
  }
}

bool _registerGuard = false;

void main() {
  setUp(() async => await _setupMusicTest());

  // auth.main();
  // backup.main();
  connectivity.main();
  database.main();
  dependency.main();
  equalizer.main();
  // firebase_sync.main();
  local_duo.main();
  lyrics.main();
  metadata_agg.main();
  metadata_clean.main();
  metadata.main();
  persona.main();
  playback.main();
  search.main();
  security.main();
  theme.main();
}
