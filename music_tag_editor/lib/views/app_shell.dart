import 'package:flutter/material.dart';
import 'package:music_tag_editor/views/search_page.dart';
import 'package:music_tag_editor/main.dart'
    as legacy; // To keep the metadata editor accessible
import 'package:music_tag_editor/widgets/mini_player.dart';
import 'package:music_tag_editor/views/playlists_view.dart';
import 'package:music_tag_editor/views/my_tracks_view.dart';
import 'package:music_tag_editor/views/home_view.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';

import 'package:music_tag_editor/services/persona_service.dart';
import 'package:music_tag_editor/models/persona_model.dart';
import 'package:music_tag_editor/views/disco_mode_view.dart';
import 'package:music_tag_editor/views/karaoke_view.dart';
import 'package:music_tag_editor/views/ringtone_maker_view.dart';
import 'package:music_tag_editor/views/vault_view.dart';
import 'package:music_tag_editor/views/party_queue_view.dart';
import 'package:music_tag_editor/views/listening_stats_view.dart';
import 'package:music_tag_editor/services/download_service.dart';

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
    return NavigationRail(
      extended: MediaQuery.of(context).size.width >= 900,
      selectedIndex: _selectedIndex >= destinations.length ? 0 : _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      labelType: MediaQuery.of(context).size.width >= 900
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: destinations
          .map((d) => NavigationRailDestination(
                icon: Icon(d.iconOutline),
                selectedIcon: Icon(d.icon),
                label: Text(d.label),
              ))
          .toList(),
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
        ];
      case AppPersona.listener:
        return [
          const _Destination('Início', Icons.home, Icons.home_outlined),
          const _Destination('Buscar', Icons.search, Icons.search_outlined),
          const _Destination('Minhas Músicas', Icons.library_music,
              Icons.library_music_outlined),
          const _Destination(
              'Playlists', Icons.playlist_play, Icons.playlist_play_outlined),
        ];
      case AppPersona.host:
        return [
          const _Destination('Disco', Icons.album, Icons.album_outlined),
          const _Destination('Karaoke', Icons.mic, Icons.mic_none),
          const _Destination(
              'Fila', Icons.queue_music, Icons.queue_music_outlined),
        ];
      case AppPersona.artisan:
        return [
          const _Destination('Toques', Icons.content_cut, Icons.content_cut),
          const _Destination('Cofre', Icons.enhanced_encryption,
              Icons.enhanced_encryption_outlined),
          const _Destination('Estatísticas', Icons.bar_chart, Icons.bar_chart),
        ];
    }
  }

  List<Widget> _getPages(AppPersona persona) {
    switch (persona) {
      case AppPersona.librarian:
        return [
          const legacy.LibraryPage(title: 'Editor de Tags'),
          const MyTracksView(),
        ];
      case AppPersona.listener:
        return [
          const HomeView(),
          const SearchPage(),
          const MyTracksView(),
          const PlaylistsView(),
        ];
      case AppPersona.host:
        return [
          const DiscoModeView(),
          const KaraokeView(track: {}), // Placeholder track
          const PartyQueueView(),
        ];
      case AppPersona.artisan:
        return [
          RingtoneMakerView(
            track: SearchResult(
              id: '0',
              title: 'Selecione uma música',
              artist: '',
              url: '',
              platform: MediaPlatform.unknown,
              thumbnail: '',
            ),
          ),
          const VaultView(),
          const ListeningStatsView(),
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
