import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return fluent.FluentApp(
        title: 'Music Tag Editor',
        theme: fluent.FluentThemeData(
          brightness: Brightness.light,
          accentColor: fluent.Colors.blue,
          visualDensity: VisualDensity.standard,
        ),
        home: const MyHomePage(),
      );
    } else {
      return MaterialApp(
        title: 'Music Tag Editor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      );
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final _windowsContent = [
    LayoutBuilder(
      builder: (context, constraints) {
        return const Center(
          child: Text('Library Page'),
        );
      },
    ),
    LayoutBuilder(
      builder: (context, constraints) {
        return const Center(
          child: Text('Editor Page'),
        );
      },
    ),
  ];

  final _nonWindowsContent = [
    const Center(
      child: Text('Library Page'),
    ),
    const Center(
      child: Text('Editor Page'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return fluent.NavigationView(
        pane: fluent.NavigationPane(
          selected: _currentIndex,
          onChanged: (index) => setState(() => _currentIndex = index),
          displayMode: fluent.PaneDisplayMode.auto,
          items: [
            fluent.PaneItem(
              icon: const Icon(fluent.FluentIcons.music_in_collection),
              title: const Text('Library'),
              body: _windowsContent[0],
            ),
            fluent.PaneItem(
              icon: const Icon(fluent.FluentIcons.edit),
              title: const Text('Editor'),
              body: _windowsContent[1],
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Music Tag Editor'),
        ),
        body: _nonWindowsContent[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit),
              label: 'Editor',
            ),
          ],
        ),
      );
    }
  }
}
