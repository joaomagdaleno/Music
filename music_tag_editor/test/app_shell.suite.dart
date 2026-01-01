@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/app_shell.dart';
import 'package:music_tag_editor/models/filename_format.dart';
import 'test_helper.dart';

void main() {
  group('AppShell Widget Tests', () {
    late ValueNotifier<bool> isOffline;

    setUp(() async {
      await setupMusicTest();
      isOffline = ValueNotifier<bool>(false);

      when(() => mockConnectivity.isOffline).thenReturn(isOffline);

      // Additional stubs specific to AppShell
      when(() => mockDb.getSetting(any())).thenAnswer((_) async => null);
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);
      when(() => mockDb.getGuestHistory()).thenAnswer((_) async => []);
      when(() => mockDb.loadFilenameFormat())
          .thenAnswer((_) async => FilenameFormat.artistTitle);
      when(() => mockDb.getLearningRules()).thenAnswer((_) async => []);
      when(() => mockDb.getMostPlayed()).thenAnswer((_) async => []);

      when(() => mockAuth.isAuthenticated).thenReturn(true);
    });

    testWidgets('Shows offline banner when offline', (tester) async {
      isOffline.value = true;

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const AppShell(),
      ));
      await tester.pump();

      expect(find.text('Modo Offline Ativado'), findsOneWidget);
    });

    testWidgets('Global Rail switches Personas', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const AppShell(),
      ));
      await tester.pumpAndSettle();

      // Initial persona is Listener (Ouvinte)
      expect(find.text('Início'), findsAtLeastNWidgets(1));

      final bottomNavBarFinder = find.byType(BottomNavigationBar);
      expect(bottomNavBarFinder, findsOneWidget);

      // Tap index 1: Librarian (Bibliotecário)
      await tester.tap(find.text('Bibliotecário'));
      await tester.pumpAndSettle();

      // Should now show Librarian tabs: Tags, Minhas Músicas
      expect(find.text('Tags'), findsAtLeastNWidgets(1));
      expect(find.text('Início'), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Adapts to wide screen (NavigationRail)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const AppShell(),
      ));
      await tester.pump();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
