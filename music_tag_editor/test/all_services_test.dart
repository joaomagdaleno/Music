/// Consolidated service tests for Music - reduces startup overhead (8 files → 1)
/// Run with: flutter test test/all_services_test.dart
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';

// Import all service tests
import 'services/auth_service_test.dart' as auth;
import 'services/cast_service_test.dart' as cast;
import 'services/connectivity_service_test.dart' as connectivity;
import 'services/desktop_integration_service_test.dart' as desktop;
import 'services/equalizer_service_test.dart' as equalizer;
import 'services/hifi_download_service_test.dart' as hifi;
import 'services/listening_stats_service_test.dart' as stats;
import 'services/theme_service_test.dart' as theme;

import 'test_helper.dart';

void main() {
  setUp(() async => await setupMusicTest());

  // Run all service tests in a single process
  auth.main();
  cast.main();
  connectivity.main();
  desktop.main();
  equalizer.main();
  hifi.main();
  stats.main();
  theme.main();
}
