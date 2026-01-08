@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_hub/features/core/screens/app_shell.dart';
import 'package:music_hub/features/library/models/filename_format.dart';
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

      final bottomNavBarFinder = find.byType(NavigationBar);
      expect(bottomNavBarFinder, findsOneWidget);

      // Tap Librarian (Bibliotecário) in nav bar
      final libItem = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Biblioteca'),
      );
      await tester.tap(libItem);
      await tester.pumpAndSettle();

      // Should now show Library tabs
      expect(find.text('Minha Biblioteca'), findsAtLeastNWidgets(1));

      // "Início" might still be in the BottomNavigationBar, but should NOT be in the AppBar anymore
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Início')),
        findsNothing,
      );

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
