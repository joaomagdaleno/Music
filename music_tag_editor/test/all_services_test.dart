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
  setUp(() async => await setupMusicTest());

  auth.main();
  backup.main();
  connectivity_root.main();
  database.main();
  database_new.main();
  download.main();
  equalizer_root.main();
  firebase_sync.main();
  local_duo.main();
  lyrics.main();
  metadata_agg.main();
  metadata_clean.main();
  metadata.main();
  persona_svc.main();
  playback.main();
  search.main();
  security.main();
  theme_root.main();

  cast.main();
  connectivity.main();
  desktop.main();
  equalizer.main();
  hifi.main();
  stats.main();
  theme.main();
}
