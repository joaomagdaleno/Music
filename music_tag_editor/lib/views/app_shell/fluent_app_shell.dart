import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_tag_editor/models/persona_model.dart';

class FluentAppShell extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final Function(int) onSelectedIndexChanged;
  final List<AppShellDestination> destinations;

  const FluentAppShell({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) => NavigationView(
        appBar: const NavigationAppBar(
          automaticallyImplyLeading: false,
          title: Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text('Music Tag Editor',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        pane: NavigationPane(
          selected: selectedIndex == 99 ? destinations.length : selectedIndex,
          onChanged: onSelectedIndexChanged,
          displayMode: PaneDisplayMode.compact,
          items: destinations
              .map<NavigationPaneItem>((d) => PaneItem(
                    icon: Icon(d.icon),
                    title: Text(d.label),
                    body: const SizedBox.shrink(),
                  ))
              .toList(),
          footerItems: <NavigationPaneItem>[
            PaneItem(
              icon: const Icon(FluentIcons.settings),
              title: const Text('Configurações'),
              body: const SizedBox.shrink(),
              onTap: () {
                // This is handled by onChanged, but safe to keep as fallback or specific action
                if (selectedIndex != 99) onSelectedIndexChanged(99);
              },
            ),
          ],
        ),
        paneBodyBuilder: (item, child) => ScaffoldPage(
          padding: EdgeInsets.zero,
          content: body,
        ),
      );
}

class AppShellDestination {
  final String label;
  final IconData icon;
  final AppPersona? persona;

  const AppShellDestination(this.label, this.icon, {this.persona});
}
