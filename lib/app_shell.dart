import 'package:flutter/material.dart';
import 'search_page.dart';
import 'main.dart' as legacy; // To keep the metadata editor accessible
import 'mini_player.dart';
import 'playlists_view.dart';
import 'my_tracks_view.dart';
import 'home_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeView(),
    const SearchPage(),
    const MyTracksView(),
    const PlaylistsView(),
    const legacy.LibraryPage(title: 'Editor de Tags'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed, // For 4+ items
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Início',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Buscar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'Minhas Músicas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.playlist_play),
                label: 'Playlists',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit_note),
                label: 'Tags',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
