import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;

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
  int _currentIndex = 0;

  bool get _isFluent {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    if (_isFluent) {
      return fluent.NavigationView(
        pane: fluent.NavigationPane(
          selected: _currentIndex,
          onChanged: (index) => setState(() => _currentIndex = index),
          displayMode: fluent.PaneDisplayMode.top,
          items: widget.destinations.map<fluent.NavigationPaneItem>((d) {
            return fluent.PaneItem(
              icon: fluent.Icon(d.fluentIcon),
              title: fluent.Text(d.label),
              body: const SizedBox.shrink(),
            );
          }).toList(),
        ),
        content: widget.children[_currentIndex],
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
