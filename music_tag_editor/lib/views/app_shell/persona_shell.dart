import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_tag_editor/services/global_navigation_service.dart';
import 'package:music_tag_editor/models/persona_model.dart';

class PersonaShell extends StatefulWidget {
  final List<PersonaDestination> destinations;
  final List<Widget> children;

  const PersonaShell({
    super.key,
    required this.destinations,
    required this.children,
  });

  @override
  State<PersonaShell> createState() => _PersonaShellState();
}

class _PersonaShellState extends State<PersonaShell> {
  AppPersona get _persona {
    final key = widget.key;
    if (key is ValueKey<AppPersona>) {
      return key.value;
    }
    return AppPersona.librarian; // Fallback
  }

  @override
  void initState() {
    super.initState();
    GlobalNavigationService.instance.addListener(_handleNavigationChange);
  }

  @override
  void dispose() {
    GlobalNavigationService.instance.removeListener(_handleNavigationChange);
    super.dispose();
  }

  void _handleNavigationChange() {
    if (mounted) setState(() {});
  }

  bool get _isFluent {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = GlobalNavigationService.instance.getSubIndex(_persona);

    if (_isFluent) {
      return fluent.NavigationView(
        pane: fluent.NavigationPane(
          selected: currentIndex,
          onChanged: (index) => GlobalNavigationService.instance.setSubIndex(_persona, index),
          displayMode: fluent.PaneDisplayMode.top,
          items: widget.destinations.map<fluent.NavigationPaneItem>((d) {
            return fluent.PaneItem(
              icon: fluent.Icon(d.fluentIcon),
              title: fluent.Text(d.label),
              body: const SizedBox.shrink(),
            );
          }).toList(),
        ),
        paneBodyBuilder: (item, body) => widget.children[currentIndex],
      );
    }

    return material.DefaultTabController(
      length: widget.destinations.length,
      child: material.Scaffold(
        appBar: material.AppBar(
          toolbarHeight: 0,
          bottom: material.TabBar(
            isScrollable: widget.destinations.length > 3,
            tabs: widget.destinations.map((d) {
              return material.Tab(
                icon: material.Icon(d.materialIcon),
                text: d.label,
              );
            }).toList(),
          ),
        ),
        body: material.TabBarView(
          children: widget.children,
        ),
      ),
    );
  }
}

class PersonaDestination {
  final String label;
  final material.IconData materialIcon;
  final fluent.IconData fluentIcon;

  const PersonaDestination({
    required this.label,
    required this.materialIcon,
    required this.fluentIcon,
  });
}
