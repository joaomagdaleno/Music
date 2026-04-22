import 'package:flutter/material.dart';
import 'package:music_tag_editor/views/search_page.dart';
import 'package:music_tag_editor/main.dart' as legacy;
import 'package:music_tag_editor/views/my_tracks_view.dart';
import 'package:music_tag_editor/views/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<_Destination> _destinations = [
    const _Destination('Editor de Tags', Icons.edit_note, Icons.edit_note_outlined),
    const _Destination('Biblioteca', Icons.library_music, Icons.library_music_outlined),
    const _Destination('Download', Icons.download, Icons.download_outlined),
    const _Destination('Configurações', Icons.settings, Icons.settings_outlined),
  ];

  final List<Widget> _pages = [
    const legacy.LibraryPage(title: 'Editor de Tags'),
    const MyTracksView(),
    const SearchPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        return Scaffold(
          body: Row(
            children: [
              if (isWide) _buildNavigationRail(),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
          bottomNavigationBar: isWide ? null : _buildBottomNavBar(),
        );
      },
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      extended: MediaQuery.of(context).size.width >= 900,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      labelType: MediaQuery.of(context).size.width >= 900
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: _destinations
          .map((d) => NavigationRailDestination(
                icon: Icon(d.iconOutline),
                selectedIcon: Icon(d.icon),
                label: Text(d.label),
              ))
          .toList(),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      items: _destinations
          .map((d) => BottomNavigationBarItem(
                icon: Icon(d.icon),
                label: d.label,
              ))
          .toList(),
    );
  }
}

class _Destination {
  final String label;
  final IconData icon;
  final IconData iconOutline;
  const _Destination(this.label, this.icon, this.iconOutline);
}
