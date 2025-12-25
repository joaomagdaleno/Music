/// Consolidated service tests for Music
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'test_helper.dart';

import 'auth_service.suite.dart' as auth;
import 'backup_service.suite.dart' as backup;
import 'connectivity_service.suite.dart' as connectivity_root;
import 'database_service.suite.dart' as database;
import 'database_service_new.suite.dart' as database_new;
import 'download_service.suite.dart' as download;
import 'equalizer_service.suite.dart' as equalizer_root;
import 'firebase_sync_service.suite.dart' as firebase_sync;
import 'local_duo_service.suite.dart' as local_duo;
import 'lyrics_service.suite.dart' as lyrics;
import 'metadata_aggregator_service.suite.dart' as metadata_agg;
import 'metadata_cleanup_service.suite.dart' as metadata_clean;
import 'metadata_service.suite.dart' as metadata;
import 'persona_service.suite.dart' as persona_svc;
import 'playback_service.suite.dart' as playback;
import 'search_service.suite.dart' as search;
import 'security_service.suite.dart' as security;
import 'theme_service.suite.dart' as theme_root;

import 'services/cast_service.suite.dart' as cast;
import 'services/connectivity_service.suite.dart' as connectivity;
import 'services/desktop_integration_service.suite.dart' as desktop;
import 'services/equalizer_service.suite.dart' as equalizer;
import 'services/hifi_download_service.suite.dart' as hifi;
import 'services/listening_stats_service.suite.dart' as stats;
import 'services/theme_service.suite.dart' as theme;

void main() {
  // Global baseline setup
  setUp(() async => await setupMusicTest());

  group('AuthService', () => auth.main());
  group('BackupService', () => backup.main());
  group('ConnectivityRoot', () => connectivity_root.main());
  group('DatabaseService', () => database.main());
  group('DatabaseServiceNew', () => database_new.main());
  group('DownloadService', () => download.main());
  group('EqualizerRoot', () => equalizer_root.main());
  group('FirebaseSync', () => firebase_sync.main());
  group('LocalDuoService', () => local_duo.main());
  group('LyricsService', () => lyrics.main());
  group('MetadataAggregator', () => metadata_agg.main());
  group('MetadataCleanup', () => metadata_clean.main());
  group('MetadataService', () => metadata.main());
  group('PersonaService', () => persona_svc.main());
  group('PlaybackService', () => playback.main());
  group('SearchService', () => search.main());
  group('SecurityService', () => security.main());
  group('ThemeRoot', () => theme_root.main());

  group('CastService', () => cast.main());
  group('ConnectivityService', () => connectivity.main());
  group('DesktopIntegration', () => desktop.main());
  group('EqualizerService', () => equalizer.main());
  group('HifiDownload', () => hifi.main());
  group('ListeningStats', () => stats.main());
  group('ThemeService', () => theme.main());
}
