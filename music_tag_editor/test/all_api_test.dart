/// Consolidated API tests for Music
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'api/discogs_api.suite.dart' as discogs;
import 'api/genius_api.suite.dart' as genius;
import 'api/lastfm_api.suite.dart' as lastfm;
import 'api/musicbrainz_api.suite.dart' as musicbrainz;
import 'discogs_api.suite.dart' as discogs_root;
import 'genius_api.suite.dart' as genius_root;
import 'lastfm_api.suite.dart' as lastfm_root;
import 'musicbrainz_api.suite.dart' as musicbrainz_root;
import 'netease_api.suite.dart' as netease;
import 'slavart_api.suite.dart' as slavart;

void main() {
  discogs.main();
  genius.main();
  lastfm.main();
  musicbrainz.main();
  discogs_root.main();
  genius_root.main();
  lastfm_root.main();
  musicbrainz_root.main();
  netease.main();
  slavart.main();
}
