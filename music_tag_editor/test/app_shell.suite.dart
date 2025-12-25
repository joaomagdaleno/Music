@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/app_shell.dart';
import 'package:music_tag_editor/views/settings_page.dart';
import 'package:music_tag_editor/views/search_page.dart';
import 'package:music_tag_editor/views/home_view.dart';
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

      await tester.pumpWidget(const MaterialApp(home: AppShell()));
      await tester.pump();

      expect(find.text('Modo Offline Ativado'), findsOneWidget);
    });

    testWidgets('Navigation switches pages', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: AppShell()));
      await tester.pumpAndSettle();

      expect(find.byType(HomeView), findsOneWidget);

      final bottomNavBarFinder = find.byType(BottomNavigationBar);
      expect(bottomNavBarFinder, findsOneWidget);

      final bottomNavBar =
          tester.widget<BottomNavigationBar>(bottomNavBarFinder);
      bottomNavBar.onTap?.call(1);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(SearchPage), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Adapts to wide screen (NavigationRail)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: AppShell()));
      await tester.pump();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
