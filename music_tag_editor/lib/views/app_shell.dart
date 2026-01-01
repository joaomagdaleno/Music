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

  Widget _buildNavigationRail(AppPersona activePersona) {
    final destinations = _getGlobalDestinations();
    final isDesktop = !kIsWeb &&
        (Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.linux ||
            Theme.of(context).platform == TargetPlatform.macOS);

    return Container(
      decoration: BoxDecoration(
        color: isDesktop ? Theme.of(context).colorScheme.surface : null,
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
        selectedIndex: destinations.indexWhere((d) => d.persona == activePersona),
        onDestinationSelected: (index) {
          if (index < destinations.length) {
            setState(() => _selectedIndex = 0);
            PersonaService.instance.setPersona(destinations[index].persona!);
          } else {
             setState(() => _selectedIndex = index);
          }
        },
        labelType: MediaQuery.of(context).size.width >= 900
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.all,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              const Icon(Icons.music_note, size: 32, color: Colors.blue),
              if (MediaQuery.of(context).size.width >= 900)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Persona Engine',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
        ),
        trailing: Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Configurações',
                onPressed: () {
                   // Open settings as a dialog or a temporary mode overlay
                   // For now, let's keep it consistent and maybe add it as a "persona" or just a specific UI.
                   // Let's use a hidden "Settings" index if we want it in IndexedStack.
                   setState(() => _selectedIndex = 99); // 99 for Settings
                },
              ),
            ),
          ),
        ),
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

  Widget _buildBottomNavBar(AppPersona activePersona) {
    final destinations = _getGlobalDestinations();
    final currentIndex = destinations.indexWhere((d) => d.persona == activePersona);
    
    return BottomNavigationBar(
      currentIndex: currentIndex == -1 ? 0 : currentIndex,
      onTap: (index) => PersonaService.instance.setPersona(destinations[index].persona!),
      type: BottomNavigationBarType.fixed,
      items: [
        ...destinations.map((d) => BottomNavigationBarItem(
              icon: Icon(d.icon),
              label: d.label,
            )),
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Configurações',
        ),
      ],
    );
  }

  Widget _buildBody(AppPersona persona) {
    if (_selectedIndex == 99) {
      return const SettingsScreen();
    }
    
    // Each Persona now has its own internal shell/container
    switch (persona) {
      case AppPersona.listener:
        return _buildListenerPersona();
      case AppPersona.librarian:
        return _buildLibrarianPersona();
      case AppPersona.host:
        return _buildHostPersona();
      case AppPersona.artisan:
        return _buildArtisanPersona();
    }
  }

  List<_Destination> _getGlobalDestinations() {
    return [
      const _Destination('Ouvinte', Icons.headset, Icons.headset_outlined, persona: AppPersona.listener),
      const _Destination('Bibliotecário', Icons.library_books, Icons.library_books_outlined, persona: AppPersona.librarian),
      const _Destination('Anfitrião', Icons.celebration, Icons.celebration_outlined, persona: AppPersona.host),
      const _Destination('Artesão', Icons.architecture, Icons.architecture_outlined, persona: AppPersona.artisan),
    ];
  }

  // --- Persona Custom Shells ---

  Widget _buildListenerPersona() {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Início'),
              Tab(icon: Icon(Icons.search), text: 'Buscar'),
              Tab(icon: Icon(Icons.library_music), text: 'Minhas Músicas'),
              Tab(icon: Icon(Icons.playlist_play), text: 'Playlists'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HomeScreen(),
            SearchScreen(),
            MyTracksScreen(),
            PlaylistsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrarianPersona() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.edit_note), text: 'Tags'),
              Tab(icon: Icon(Icons.library_music), text: 'Minhas Músicas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LibraryScreen(title: 'Editor de Tags'),
            MyTracksScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildHostPersona() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.album), text: 'Disco'),
              Tab(icon: Icon(Icons.mic), text: 'Karaoke'),
              Tab(icon: Icon(Icons.queue_music), text: 'Fila'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DiscoModeScreen(),
            KaraokeScreen(track: {}),
            PartyQueueScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildArtisanPersona() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.content_cut), text: 'Toques'),
              Tab(icon: Icon(Icons.enhanced_encryption), text: 'Cofre'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Estatísticas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
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
          ],
        ),
      ),
    );
  }
}

class _Destination {
  final String label;
  final IconData icon;
  final IconData iconOutline;
  final AppPersona? persona;
  const _Destination(this.label, this.icon, this.iconOutline, {this.persona});
}
