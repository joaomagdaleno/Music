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
import 'package:music_tag_editor/screens/library/local_sources_screen.dart';
import 'package:music_tag_editor/models/search_models.dart';
import 'package:music_tag_editor/views/app_shell/fluent_app_shell.dart';
import 'package:music_tag_editor/views/app_shell/material_app_shell.dart';
import 'package:music_tag_editor/views/app_shell/persona_shell.dart';
import 'package:music_tag_editor/services/global_navigation_service.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentIcons;

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    PersonaService.instance.addListener(_handlePersonaChange);
    GlobalNavigationService.instance.addListener(_handleNavigationChange);
  }

  @override
  void dispose() {
    PersonaService.instance.removeListener(_handlePersonaChange);
    GlobalNavigationService.instance.removeListener(_handleNavigationChange);
    super.dispose();
  }

  void _handleNavigationChange() {
    if (mounted) setState(() {});
  }

  void _handlePersonaChange() {
    final persona = PersonaService.instance.activePersona;
    final destinations = _getGlobalDestinations();
    final index = destinations.indexWhere((d) => d.persona == persona);

    // If a persona is selected, and we are not already on that persona's tab,
    // and we are NOT on a special global tab (Início/Buscar), update the index.
    if (index != -1 && GlobalNavigationService.instance.mainIndex != index) {
      GlobalNavigationService.instance.setMainIndex(index);
    }
  }

  void _onSelectedIndexChanged(
      int index, List<AppShellDestination> destinations) {
    int targetIndex = index;
    if (index == 99 || index == destinations.length) {
      targetIndex = 99; // Settings
    } else if (index < destinations.length) {
      final persona = destinations[index].persona;
      if (persona != null) {
        PersonaService.instance.setPersona(persona);
      }
    }
    GlobalNavigationService.instance.setMainIndex(targetIndex);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = GlobalNavigationService.instance.mainIndex;

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
                    selectedIndex: selectedIndex,
                    onSelectedIndexChanged: (index) =>
                        _onSelectedIndexChanged(index, appShellDestinations),
                    destinations: appShellDestinations,
                  )
                : MaterialAppShell(
                    body: _buildBody(persona),
                    selectedIndex: selectedIndex,
                    onSelectedIndexChanged: (index) =>
                        _onSelectedIndexChanged(index, appShellDestinations),
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
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;
  }

  Widget _buildOfflineBanner() => Container(
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

  Widget _buildBody(AppPersona persona) {
    final selectedIndex = GlobalNavigationService.instance.mainIndex;
    if (selectedIndex == 99) {
      return const SettingsScreen();
    }

    if (selectedIndex == 0) {
      return const HomeScreen();
    }

    if (selectedIndex == 1) {
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

  List<_Destination> _getGlobalDestinations() => [
        const _Destination(
            'Início', Icons.home, Icons.home_outlined, FluentIcons.home),
        const _Destination(
            'Buscar', Icons.search, Icons.search_outlined, FluentIcons.search),
        const _Destination('Bibliotecário', Icons.library_books,
            Icons.library_books_outlined, FluentIcons.library,
            persona: AppPersona.librarian),
        const _Destination('Anfitrião', Icons.celebration,
            Icons.celebration_outlined, FluentIcons.party_leader,
            persona: AppPersona.host),
        const _Destination('Artesão', Icons.architecture,
            Icons.architecture_outlined, FluentIcons.developer_tools,
            persona: AppPersona.artisan),
      ];

  Widget _buildLibrarianPersona() => const PersonaShell(
        key: ValueKey(AppPersona.librarian),
        destinations: [
          PersonaDestination(
              label: 'Tags',
              materialIcon: Icons.edit_note,
              fluentIcon: FluentIcons.tag),
          PersonaDestination(
              label: 'Biblioteca',
              materialIcon: Icons.library_music,
              fluentIcon: FluentIcons.music_note),
          PersonaDestination(
              label: 'Playlists',
              materialIcon: Icons.playlist_play,
              fluentIcon: FluentIcons.list),
          PersonaDestination(
              label: 'Pastas',
              materialIcon: Icons.folder,
              fluentIcon: FluentIcons.folder),
        ],
        children: [
          LibraryScreen(),
          MyTracksScreen(),
          PlaylistsScreen(),
          LocalSourcesScreen(),
        ],
      );

  Widget _buildHostPersona() => const PersonaShell(
        key: ValueKey(AppPersona.host),
        destinations: [
          PersonaDestination(
              label: 'Disco',
              materialIcon: Icons.album,
              fluentIcon: FluentIcons.album),
          PersonaDestination(
              label: 'Karaoke',
              materialIcon: Icons.mic,
              fluentIcon: FluentIcons.microphone),
          PersonaDestination(
              label: 'Fila',
              materialIcon: Icons.queue_music,
              fluentIcon: FluentIcons.list),
        ],
        children: [
          DiscoModeScreen(),
          KaraokeScreen(track: {}),
          PartyQueueScreen(),
        ],
      );

  Widget _buildArtisanPersona() => PersonaShell(
        key: const ValueKey(AppPersona.artisan),
        destinations: const [
          PersonaDestination(
              label: 'Toques',
              materialIcon: Icons.content_cut,
              fluentIcon: FluentIcons.cut),
          PersonaDestination(
              label: 'Cofre',
              materialIcon: Icons.enhanced_encryption,
              fluentIcon: FluentIcons.lock),
          PersonaDestination(
              label: 'Estatísticas',
              materialIcon: Icons.bar_chart,
              fluentIcon: FluentIcons.b_i_dashboard),
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
              isVault: false,
            ),
          ),
          const VaultScreen(),
          const ListeningStatsScreen(),
        ],
      );
}

class _Destination {
  final String label;
  final IconData icon;
  final IconData iconOutline;
  final IconData fluentIcon;
  final AppPersona? persona;
  const _Destination(this.label, this.icon, this.iconOutline, this.fluentIcon,
      {this.persona});
}
