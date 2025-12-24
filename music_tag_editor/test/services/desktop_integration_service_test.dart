@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/desktop_integration_service.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';

class MockSystemTray extends Mock implements SystemTray {}

class MockWindowManager extends Mock implements WindowManager {}

class FakeMenu extends Fake implements Menu {}

class FakeWindowOptions extends Fake implements WindowOptions {}

class MockMenu extends Mock implements Menu {}

void main() {
  late DesktopIntegrationService service;
  late MockSystemTray mockSystemTray;
  late MockWindowManager mockWindowManager;
  late MockMenu mockMenu;

  setUpAll(() {
    registerFallbackValue(FakeMenu());
    registerFallbackValue(FakeWindowOptions());
  });

  setUp(() {
    mockSystemTray = MockSystemTray();
    mockWindowManager = MockWindowManager();
    mockMenu = MockMenu();

    // Reset singleton
    DesktopIntegrationService.instance = DesktopIntegrationService.test(
      systemTray: mockSystemTray,
      windowManager: mockWindowManager,
      menuFactory: () => mockMenu,
    );
    service = DesktopIntegrationService.instance;

    when(() => mockWindowManager.ensureInitialized()).thenAnswer((_) async {});
    when(() => mockSystemTray.initSystemTray(
        iconPath: any(named: 'iconPath'),
        title: any(named: 'title'))).thenAnswer((_) async => true);
    when(() => mockSystemTray.setContextMenu(any())).thenAnswer((_) async {});
    when(() => mockSystemTray.registerSystemTrayEventHandler(any()))
        .thenAnswer((_) {});
    when(() => mockMenu.buildFrom(any())).thenAnswer((_) async => true);
    when(() => mockWindowManager.waitUntilReadyToShow(any(), any()))
        .thenAnswer((invocation) async {
      final callback = invocation.positionalArguments[1] as Function();
      await callback();
    });
    when(() => mockWindowManager.show()).thenAnswer((_) async {});
    when(() => mockWindowManager.focus()).thenAnswer((_) async {});
  });

  test('init calls initialization methods', () async {
    // We assume running on Windows context or we can't test platform check easily without platform override
    // Assuming the test runner environment reports Platform.isWindows as true on Windows
    // or we might need to mock Platform if possible, but dart:io Platform is hard mock.
    // However, user said OS is Windows, so tests running on Windows should pass logic.

    await service.init();

    verify(() => mockWindowManager.ensureInitialized()).called(1);
    verify(() => mockSystemTray.initSystemTray(
        iconPath: any(named: 'iconPath'),
        title: any(named: 'title'))).called(1);
    verify(() => mockWindowManager.waitUntilReadyToShow(any(), any()))
        .called(1);
    verify(() => mockWindowManager.show()).called(1);
  });

  test('hideToTray calls windowManager.hide()', () async {
    when(() => mockWindowManager.hide()).thenAnswer((_) async {});
    await service.hideToTray();
    verify(() => mockWindowManager.hide()).called(1);
  });
}
