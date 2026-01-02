import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_tag_editor/models/persona_model.dart';
import 'package:music_tag_editor/services/persona_service.dart';
import 'package:music_tag_editor/widgets/mini_player.dart';

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
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: const NavigationAppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: Text('Music Tag Editor', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      pane: NavigationPane(
        selected: selectedIndex,
        onChanged: (index) {
          if (index < destinations.length) {
            final dest = destinations[index];
            if (dest.persona != null) {
              PersonaService.instance.setPersona(dest.persona!);
            }
          }
          onSelectedIndexChanged(index);
        },
        displayMode: PaneDisplayMode.compact,
        items: destinations.map((d) {
          return PaneItem(
            icon: Icon(d.icon),
            title: Text(d.label),
            body: const SizedBox.shrink(),
          );
        }).toList(),
        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Configurações'),
            body: const SizedBox.shrink(),
            onTap: () => onSelectedIndexChanged(99),
          ),
        ],
      ),
      content: Column(
        children: [
          Expanded(child: body),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class AppShellDestination {
  final String label;
  final IconData icon;
  final AppPersona? persona;

  const AppShellDestination(this.label, this.icon, {this.persona});
}
