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
  // Global baseline setup
  setUp(() async => await setupMusicTest());

  group('AppShell', () => app_shell.main());
  group('BackupView', () => backup_view.main());
  group('DiscoMode', () => disco_mode.main());
  group('DownloadPage', () => download_page.main());
  group('HomeView', () => home.main());
  group('KaraokeView', () => karaoke.main());
  group('ListeningStats', () => listening_stats.main());
  group('LoginPage', () => login.main());
  group('MiniPlayer', () => mini_player.main());
  group('MoodExplorer', () => mood_explorer.main());
  group('MyTracks', () => my_tracks.main());
  group('PartyQueue', () => party_queue.main());
  group('PersonasWidget', () => personas_widget.main());
  group('PlayerScreen', () => player.main());
  group('PlaylistDetail', () => playlist_detail.main());
  group('PlaylistImporter', () => playlist_importer.main());
  group('PlaylistsView', () => playlists.main());
  group('RemoteLibrary', () => remote_lib.main());
  group('RingtoneMaker', () => ringtone_maker.main());
  group('SearchPage', () => search_page.main());
  group('SettingsPage', () => settings.main());
  group('SmartLibrary', () => smart_lib.main());
  group('VaultView', () => vault.main());
}
