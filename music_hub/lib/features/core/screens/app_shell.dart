import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_hub/features/home/home_screen.dart';
import 'package:music_hub/features/library/screens/library_screen.dart';
import 'package:music_hub/features/discovery/screens/discovery_screen.dart';
import 'package:music_hub/features/settings/screens/settings_screen.dart';
import 'package:music_hub/core/widgets/mini_player.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),      
    const LibraryScreen(),   
    const DiscoveryScreen(), 
    const SettingsScreen(),  
  ];

  @override
  Widget build(BuildContext context) {
    final isFluent = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows);

    if (isFluent) {
      return fluent.NavigationView(
        appBar: const fluent.NavigationAppBar(
          title: Text('Music Hub'),
          automaticallyImplyLeading: false,
        ),
        pane: fluent.NavigationPane(
          selected: _currentIndex,
          onChanged: (i) => setState(() => _currentIndex = i),
          displayMode: fluent.PaneDisplayMode.compact,
          items: [
            fluent.PaneItem(
              icon: const Icon(fluent.FluentIcons.home),
              title: const Text('Início'),
              body: const SizedBox.shrink(),
            ),
            fluent.PaneItem(
              icon: const Icon(fluent.FluentIcons.music_note),
              title: const Text('Biblioteca'),
              body: const SizedBox.shrink(),
            ),
            fluent.PaneItem(
              icon: const Icon(fluent.FluentIcons.cloud_download),
              title: const Text('Explorar'),
              body: const SizedBox.shrink(),
            ),
            fluent.PaneItem(
              icon: const Icon(fluent.FluentIcons.settings),
              title: const Text('Ajustes'),
              body: const SizedBox.shrink(),
            ),
          ],
        ),
        content: Stack(
          children: [
            fluent.ScaffoldPage(content: _screens[_currentIndex]),
            const Positioned(
              bottom: 0, left: 0, right: 0,
              child: MiniPlayer(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          const Positioned(
            bottom: 0, left: 0, right: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.library_music), label: 'Biblioteca'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Explorar'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
