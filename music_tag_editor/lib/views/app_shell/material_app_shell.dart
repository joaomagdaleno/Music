import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/persona_service.dart';
import 'package:music_tag_editor/widgets/mini_player.dart';
import 'fluent_app_shell.dart'; // Reuse the destination model

class MaterialAppShell extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final Function(int) onSelectedIndexChanged;
  final List<AppShellDestination> destinations;

  const MaterialAppShell({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final persona = PersonaService.instance.activePersona;
        final currentIndex = destinations.indexWhere((d) => d.persona == persona);
        final effectiveIndex = selectedIndex == 99 ? destinations.length : (currentIndex == -1 ? 0 : currentIndex);

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: effectiveIndex,
                  onDestinationSelected: (index) {
                    if (index == destinations.length) {
                      onSelectedIndexChanged(99);
                    } else {
                      final dest = destinations[index];
                      if (dest.persona != null) {
                        PersonaService.instance.setPersona(dest.persona!);
                      }
                      onSelectedIndexChanged(index);
                    }
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    ...destinations.map((d) => NavigationRailDestination(
                          icon: Icon(d.icon),
                          label: Text(d.label),
                        )),
                    const NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Configurações'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: body),
                      const MiniPlayer(),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              Expanded(child: body),
              const MiniPlayer(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: effectiveIndex >= destinations.length ? destinations.length : effectiveIndex,
            onTap: (index) {
              if (index == destinations.length) {
                onSelectedIndexChanged(99);
              } else {
                if (index < destinations.length) {
                  final dest = destinations[index];
                  if (dest.persona != null) {
                    PersonaService.instance.setPersona(dest.persona!);
                  }
                }
                onSelectedIndexChanged(index);
              }
            },
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
          ),
        );
      },
    );
  }
}
