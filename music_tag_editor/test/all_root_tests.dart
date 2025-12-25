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
  auth.main();
  backup.main();
  connectivity.main();
  database.main();
  dependency.main();
  equalizer.main();
  firebase_sync.main();
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
