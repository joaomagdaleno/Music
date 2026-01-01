import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music_tag_editor/screens/search/search_screen.dart';

import 'package:music_tag_editor/widgets/mini_player.dart';
import 'package:music_tag_editor/screens/playlists/playlists_screen.dart';
import 'package:music_tag_editor/screens/tracks/my_tracks_screen.dart';
import 'package:music_tag_editor/screens/home/home_screen.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';

import 'package:music_tag_editor/services/persona_service.dart';
import 'package:music_tag_editor/models/persona_model.dart';
import 'package:music_tag_editor/screens/tracks/ringtone_maker_screen.dart';
import 'package:music_tag_editor/screens/disco/disco_mode_screen.dart';
import 'package:music_tag_editor/screens/disco/karaoke_screen.dart';
import 'package:music_tag_editor/screens/disco/party_queue_screen.dart';
import 'package:music_tag_editor/screens/vault/vault_screen.dart';
import 'package:music_tag_editor/screens/stats/listening_stats_screen.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/screens/library/library_screen.dart';
import 'package:music_tag_editor/screens/settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PersonaService.instance,
      builder: (context, child) {
        final persona = PersonaService.instance.activePersona;

        return ValueListenableBuilder<bool>(
          valueListenable: ConnectivityService.instance.isOffline,
          builder: (context, isOffline, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;

                return Scaffold(
                  body: Column(
                    children: [
                      if (isOffline) _buildOfflineBanner(),
                      Expanded(
                        child: Row(
                          children: [
                            if (isWide) _buildNavigationRail(persona),
                            Expanded(child: _buildBody(persona)),
                          ],
                        ),
                      ),
                      const MiniPlayer(),
                    ],
                  ),
                  bottomNavigationBar:
                      isWide ? null : _buildBottomNavBar(persona),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: const Center(
        child: Text(
          'Modo Offline Ativado',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationRail(AppPersona persona) {
    final destinations = _getDestinations(persona);
    final isDesktop = !kIsWeb &&
        (Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.linux ||
            Theme.of(context).platform == TargetPlatform.macOS);

    return Container(
      decoration: BoxDecoration(
        color: isDesktop
            ? Theme.of(context).colorScheme.surface
            : null,
        border: isDesktop
            ? Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              )
            : null,
      ),
      child: NavigationRail(
        extended: MediaQuery.of(context).size.width >= 900,
        selectedIndex: _selectedIndex >= destinations.length ? 0 : _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        labelType: MediaQuery.of(context).size.width >= 900
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.all,
        backgroundColor: Colors.transparent, // Allow container color to show
        destinations: destinations
            .map((d) => NavigationRailDestination(
                  icon: Icon(d.iconOutline),
                  selectedIcon: Icon(d.icon),
                  label: Text(d.label),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBottomNavBar(AppPersona persona) {
    final destinations = _getDestinations(persona);
    return BottomNavigationBar(
      currentIndex: _selectedIndex >= destinations.length ? 0 : _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      items: destinations
          .map((d) => BottomNavigationBarItem(
                icon: Icon(d.icon),
                label: d.label,
              ))
          .toList(),
    );
  }

  Widget _buildBody(AppPersona persona) {
    final pages = _getPages(persona);
    final index = _selectedIndex >= pages.length ? 0 : _selectedIndex;
    return IndexedStack(
      index: index,
      children: pages,
    );
  }

  List<_Destination> _getDestinations(AppPersona persona) {
    switch (persona) {
      case AppPersona.librarian:
        return [
          const _Destination('Tags', Icons.edit_note, Icons.edit_note_outlined),
          const _Destination('Minhas Músicas', Icons.library_music,
              Icons.library_music_outlined),
          const _Destination('Configurações', Icons.settings, Icons.settings_outlined),
        ];
      case AppPersona.listener:
        return [
          const _Destination('Início', Icons.home, Icons.home_outlined),
          const _Destination('Buscar', Icons.search, Icons.search_outlined),
          const _Destination('Minhas Músicas', Icons.library_music,
              Icons.library_music_outlined),
          const _Destination(
              'Playlists', Icons.playlist_play, Icons.playlist_play_outlined),
          const _Destination('Configurações', Icons.settings, Icons.settings_outlined),
        ];
      case AppPersona.host:
        return [
          const _Destination('Disco', Icons.album, Icons.album_outlined),
          const _Destination('Karaoke', Icons.mic, Icons.mic_none),
          const _Destination(
              'Fila', Icons.queue_music, Icons.queue_music_outlined),
          const _Destination('Configurações', Icons.settings, Icons.settings_outlined),
        ];
      case AppPersona.artisan:
        return [
          const _Destination('Toques', Icons.content_cut, Icons.content_cut),
          const _Destination('Cofre', Icons.enhanced_encryption,
              Icons.enhanced_encryption_outlined),
          const _Destination('Estatísticas', Icons.bar_chart, Icons.bar_chart),
          const _Destination('Configurações', Icons.settings, Icons.settings_outlined),
        ];
    }
  }

  List<Widget> _getPages(AppPersona persona) {
    switch (persona) {
      case AppPersona.librarian:
        return [
          const LibraryScreen(title: 'Editor de Tags'),
          const MyTracksScreen(),
          const SettingsScreen(),
        ];
      case AppPersona.listener:
        return [
          const HomeScreen(),
          const SearchScreen(),
          const MyTracksScreen(),
          const PlaylistsScreen(),
          const SettingsScreen(),
        ];
      case AppPersona.host:
        return [
          const DiscoModeScreen(),
          const KaraokeScreen(track: {}), // Placeholder track
          const PartyQueueScreen(),
          const SettingsScreen(),
        ];
      case AppPersona.artisan:
        return [
          RingtoneMakerScreen(
            track: SearchResult(
              id: '0',
              title: 'Selecione uma música',
              artist: '',
              url: '',
              platform: MediaPlatform.unknown,
              thumbnail: '',
            ),
          ),
          const VaultScreen(),
          const ListeningStatsScreen(),
          const SettingsScreen(),
        ];
    }
  }
}

class _Destination {
  final String label;
  final IconData icon;
  final IconData iconOutline;
  const _Destination(this.label, this.icon, this.iconOutline);
}
