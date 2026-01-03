import 'package:flutter/material.dart';
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
        final effectiveIndex = selectedIndex == 99 ? destinations.length : selectedIndex;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: effectiveIndex,
                  onDestinationSelected: onSelectedIndexChanged,
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
                  child: body,
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: effectiveIndex >= destinations.length ? destinations.length : effectiveIndex,
            onTap: onSelectedIndexChanged,
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
