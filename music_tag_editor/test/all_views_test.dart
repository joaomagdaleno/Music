/// Consolidated view and widget tests for Music
@Tags(['widget'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'test_helper.dart';

import 'app_shell.suite.dart' as app_shell;
import 'backup_view.suite.dart' as backup_view;
import 'disco_mode_view.suite.dart' as disco_mode;
import 'download_page.suite.dart' as download_page;
import 'home_view.suite.dart' as home;
import 'karaoke_view.suite.dart' as karaoke;
import 'listening_stats_view.suite.dart' as listening_stats;
import 'login_page.suite.dart' as login;
import 'mini_player.suite.dart' as mini_player;
import 'mood_explorer_view.suite.dart' as mood_explorer;
import 'my_tracks_view.suite.dart' as my_tracks;
import 'party_queue_view.suite.dart' as party_queue;
import 'personas_widget.suite.dart' as personas_widget;
import 'player_screen.suite.dart' as player;
import 'playlist_detail_screen.suite.dart' as playlist_detail;
import 'playlist_importer_view.suite.dart' as playlist_importer;
import 'playlists_view.suite.dart' as playlists;
import 'remote_library_view.suite.dart' as remote_lib;
import 'ringtone_maker_view.suite.dart' as ringtone_maker;
import 'search_page.suite.dart' as search_page;
import 'settings_page.suite.dart' as settings;
import 'smart_library_view.suite.dart' as smart_lib;
import 'vault_view.suite.dart' as vault;

void main() {
  setUp(() async => await setupMusicTest());

  app_shell.main();
  backup_view.main();
  disco_mode.main();
  download_page.main();
  home.main();
  karaoke.main();
  listening_stats.main();
  login.main();
  mini_player.main();
  mood_explorer.main();
  my_tracks.main();
  party_queue.main();
  personas_widget.main();
  player.main();
  playlist_detail.main();
  playlist_importer.main();
  playlists.main();
  remote_lib.main();
  ringtone_maker.main();
  search_page.main();
  settings.main();
  smart_lib.main();
  vault.main();
}
