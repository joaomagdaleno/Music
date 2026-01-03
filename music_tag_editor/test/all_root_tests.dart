/// Consolidated root tests for Music - reduces startup overhead
@Tags(['root'])
library;

import 'package:flutter_test/flutter_test.dart';

// Import all root tests
import 'auth_service.suite.dart' as auth;
import 'backup_service.suite.dart' as backup;
import 'connectivity_service.suite.dart' as connectivity;
import 'database_service.suite.dart' as database;
import 'dependency_manager.suite.dart' as dependency;
import 'equalizer_service.suite.dart' as equalizer;
import 'firebase_sync_service.suite.dart' as firebase_sync;
import 'local_duo_service.suite.dart' as local_duo;
import 'lyrics_service.suite.dart' as lyrics;
import 'metadata_aggregator_service.suite.dart' as metadata_agg;
import 'metadata_cleanup_service.suite.dart' as metadata_clean;
import 'metadata_service.suite.dart' as metadata;
import 'persona_service.suite.dart' as persona;
import 'playback_service.suite.dart' as playback;
import 'search_service.suite.dart' as search;
import 'security_service.suite.dart' as security;
import 'theme_service.suite.dart' as theme;

void main() {
  group('AuthService', () => auth.main());
  group('BackupService', () => backup.main());
  group('ConnectivityService', () => connectivity.main());
  group('DatabaseService', () => database.main());
  group('DependencyManager', () => dependency.main());
  group('EqualizerService', () => equalizer.main());
  group('FirebaseSyncService', () => firebase_sync.main());
  group('LocalDuoService', () => local_duo.main());
  group('LyricsService', () => lyrics.main());
  group('MetadataAggregator', () => metadata_agg.main());
  group('MetadataCleanup', () => metadata_clean.main());
  group('MetadataService', () => metadata.main());
  group('PersonaService', () => persona.main());
  group('PlaybackService', () => playback.main());
  group('SearchService', () => search.main());
  group('SecurityService', () => security.main());
  group('ThemeService', () => theme.main());
}
