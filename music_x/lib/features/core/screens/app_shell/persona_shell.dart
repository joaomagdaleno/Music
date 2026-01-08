import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_hub/core/services/global_navigation_service.dart';
import 'package:music_hub/features/library/models/persona_model.dart';

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

  bool _isFluent(BuildContext context) {
    if (kIsWeb) return false;
    final platform = material.Theme.of(context).platform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;
  }

  void _onTabChanged(int index) {
    GlobalNavigationService.instance.setSubIndex(_persona, index);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = GlobalNavigationService.instance.getSubIndex(_persona);

    if (_isFluent(context)) {
      return fluent.NavigationView(
        pane: fluent.NavigationPane(
          selected: currentIndex,
          onChanged: _onTabChanged,
          displayMode: fluent.PaneDisplayMode.top,
          items: widget.destinations
              .map<fluent.NavigationPaneItem>((d) => fluent.PaneItem(
                    icon: fluent.Icon(d.fluentIcon),
                    title: fluent.Text(d.label),
                    body: const SizedBox.shrink(),
                  ))
              .toList(),
        ),
        paneBodyBuilder: (item, body) => widget.children[currentIndex],
      );
    }

    return material.DefaultTabController(
      length: widget.destinations.length,
      initialIndex: currentIndex,
      child: material.Scaffold(
        appBar: material.AppBar(
          toolbarHeight: 0,
          bottom: material.TabBar(
            onTap: _onTabChanged,
            isScrollable: widget.destinations.length > 3,
            tabs: widget.destinations
                .map((d) => material.Tab(
                      icon: material.Icon(d.materialIcon),
                      text: d.label,
                    ))
                .toList(),
          ),
        ),
        body: material.TabBarView(
          physics: const material
              .NeverScrollableScrollPhysics(), // Sync with outer sub-index
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
