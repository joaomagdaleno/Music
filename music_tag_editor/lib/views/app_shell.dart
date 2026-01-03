import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music_tag_editor/screens/search/search_screen.dart';
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
import 'package:music_tag_editor/screens/settings/settings_screen.dart';
import 'package:music_tag_editor/screens/library/library_screen.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/views/app_shell/fluent_app_shell.dart';
import 'package:music_tag_editor/views/app_shell/material_app_shell.dart';
import 'package:music_tag_editor/views/app_shell/persona_shell.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentIcons;

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    PersonaService.instance.addListener(_handlePersonaChange);
  }

  @override
  void dispose() {
    PersonaService.instance.removeListener(_handlePersonaChange);
    super.dispose();
  }

  void _handlePersonaChange() {
    final persona = PersonaService.instance.activePersona;
    final destinations = _getGlobalDestinations();
    final index = destinations.indexWhere((d) => d.persona == persona);
    
    // If a persona is selected, and we are not already on that persona's tab,
    // and we are NOT on a special global tab (Início/Buscar), update the index.
    // Actually, if we are on Home (0) and a persona is selected via card, we WANT to switch.
    if (index != -1 && _selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PersonaService.instance,
      builder: (context, child) {
        final persona = PersonaService.instance.activePersona;

        return ValueListenableBuilder<bool>(
          valueListenable: ConnectivityService.instance.isOffline,
          builder: (context, isOffline, child) {
            final appShellDestinations = _getGlobalDestinations()
                .map((d) => AppShellDestination(
                      d.label,
                      _isFluent(context) ? d.fluentIcon : d.iconOutline,
                      persona: d.persona,
                    ))
                .toList();

            final appShell = _isFluent(context)
                ? FluentAppShell(
                    body: _buildBody(persona),
                    selectedIndex: _selectedIndex,
                    onSelectedIndexChanged: (index) =>
                        setState(() => _selectedIndex = index),
                    destinations: appShellDestinations,
                  )
                : MaterialAppShell(
                    body: _buildBody(persona),
                    selectedIndex: _selectedIndex,
                    onSelectedIndexChanged: (index) {
                      int targetIndex = index;
                      if (index == appShellDestinations.length) {
                        targetIndex = 99;
                      } else if (index < appShellDestinations.length) {
                        final persona = appShellDestinations[index].persona;
                        if (persona != null) {
                          PersonaService.instance.setPersona(persona);
                        }
                      }
                      setState(() => _selectedIndex = targetIndex);
                    },
                    destinations: appShellDestinations,
                  );

            if (!isOffline) return appShell;

            return Column(
              children: [
                _buildOfflineBanner(),
                Expanded(child: appShell),
              ],
            );
          },
        );
      },
    );
  }

  bool _isFluent(BuildContext context) {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
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

  Widget _buildBody(AppPersona persona) {
    if (_selectedIndex == 99) {
      return const SettingsScreen();
    }
    
    if (_selectedIndex == 0) {
      return const HomeScreen();
    }
    
    if (_selectedIndex == 1) {
      return const SearchScreen();
    }
    
    // Each Persona now has its own internal shell/container
    switch (persona) {
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
      const _Destination('Início', Icons.home, Icons.home_outlined, FluentIcons.home),
      const _Destination('Buscar', Icons.search, Icons.search_outlined, FluentIcons.search),
      const _Destination('Bibliotecário', Icons.library_books, Icons.library_books_outlined, FluentIcons.library, persona: AppPersona.librarian),
      const _Destination('Anfitrião', Icons.celebration, Icons.celebration_outlined, FluentIcons.party_leader, persona: AppPersona.host),
      const _Destination('Artesão', Icons.architecture, Icons.architecture_outlined, FluentIcons.developer_tools, persona: AppPersona.artisan),
    ];
  }


  Widget _buildLibrarianPersona() {
    return const PersonaShell(
      key: ValueKey(AppPersona.librarian),
      destinations: [
        PersonaDestination(label: 'Tags', materialIcon: Icons.edit_note, fluentIcon: FluentIcons.tag),
        PersonaDestination(label: 'Minhas Músicas', materialIcon: Icons.library_music, fluentIcon: FluentIcons.music_note),
        PersonaDestination(label: 'Playlists', materialIcon: Icons.playlist_play, fluentIcon: FluentIcons.list),
      ],
      children: [
        LibraryScreen(title: 'Editor de Tags'),
        MyTracksScreen(),
        PlaylistsScreen(),
      ],
    );
  }

  Widget _buildHostPersona() {
    return const PersonaShell(
      key: ValueKey(AppPersona.host),
      destinations: [
        PersonaDestination(label: 'Disco', materialIcon: Icons.album, fluentIcon: FluentIcons.album),
        PersonaDestination(label: 'Karaoke', materialIcon: Icons.mic, fluentIcon: FluentIcons.microphone),
        PersonaDestination(label: 'Fila', materialIcon: Icons.queue_music, fluentIcon: FluentIcons.list),
      ],
      children: [
        DiscoModeScreen(),
        KaraokeScreen(track: {}),
        PartyQueueScreen(),
      ],
    );
  }

  Widget _buildArtisanPersona() {
    return PersonaShell(
      key: const ValueKey(AppPersona.artisan),
      destinations: const [
        PersonaDestination(label: 'Toques', materialIcon: Icons.content_cut, fluentIcon: FluentIcons.cut),
        PersonaDestination(label: 'Cofre', materialIcon: Icons.enhanced_encryption, fluentIcon: FluentIcons.lock),
        PersonaDestination(label: 'Estatísticas', materialIcon: Icons.bar_chart, fluentIcon: FluentIcons.b_i_dashboard),
      ],
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
    );
  }
}

class _Destination {
  final String label;
  final IconData icon;
  final IconData iconOutline;
  final IconData fluentIcon;
  final AppPersona? persona;
  const _Destination(this.label, this.icon, this.iconOutline, this.fluentIcon, {this.persona});
}
