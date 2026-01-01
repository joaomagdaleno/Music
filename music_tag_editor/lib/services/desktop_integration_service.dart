import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:music_tag_editor/services/startup_logger.dart';

class DesktopIntegrationService {
  static DesktopIntegrationService _instance =
      DesktopIntegrationService._internal();
  static DesktopIntegrationService get instance => _instance;

  @visibleForTesting
  static set instance(DesktopIntegrationService mock) => _instance = mock;

  final SystemTray _systemTray;
  final WindowManager _windowManager;
  final Menu Function() _menuFactory;

  DesktopIntegrationService._internal(
      {SystemTray? systemTray,
      WindowManager? manager,
      Menu Function()? menuFactory})
      : _systemTray = systemTray ?? SystemTray(),
        _windowManager = manager ?? windowManager,
        _menuFactory = menuFactory ?? (() => Menu());

  @visibleForTesting
  factory DesktopIntegrationService.test(
      {SystemTray? systemTray,
      WindowManager? windowManager,
      Menu Function()? menuFactory}) {
    return DesktopIntegrationService._internal(
      systemTray: systemTray,
      manager: windowManager,
      menuFactory: menuFactory,
    );
  }

  Future<void> init() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return;
    }

    try {
      await StartupLogger.log('Desktop: ensuring WindowManager initialized');
      await _windowManager.ensureInitialized();

      const String iconPath = 'assets/app_icon.ico';

      await StartupLogger.log('Desktop: initializing SystemTray');
      await _systemTray.initSystemTray(
        iconPath: iconPath,
        title: "Music App",
      );

      await StartupLogger.log('Desktop: creating menu');
      // Create the menu
      final Menu menu = _menuFactory();
      await menu.buildFrom([
        MenuItemLabel(
            label: 'Mostrar', onClicked: (menuItem) => _windowManager.show()),
        MenuItemLabel(
            label: 'Ocultar', onClicked: (menuItem) => _windowManager.hide()),
        MenuSeparator(),
        MenuItemLabel(
            label: 'Sair', onClicked: (menuItem) => _windowManager.close()),
      ]);

      await StartupLogger.log('Desktop: setting context menu');
      await _systemTray.setContextMenu(menu);

      // Handle events
      _systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == 'leftClick' || eventName == 'click') {
          Platform.isWindows
              ? _windowManager.show()
              : _systemTray.popUpContextMenu();
        } else if (eventName == 'rightClick') {
          Platform.isWindows
              ? _systemTray.popUpContextMenu()
              : _windowManager.show();
        }
      });

      // Configure window manager
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1280, 720),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );

      await StartupLogger.log('Desktop: waiting for WindowManager ready');
      await _windowManager.waitUntilReadyToShow(windowOptions, () async {
        await _windowManager.show();
        await _windowManager.focus();
      });
      
      await StartupLogger.log('Desktop: init complete');
    } catch (e, stack) {
      await StartupLogger.log('❌ DesktopIntegrationService error: $e');
      await StartupLogger.log(stack.toString());
      // Don't rethrow, strictly speaking, logging it might be enough to see what's wrong without crashing startup entirely?
      // But user wants to debug, so let's let it crash if needed or just log.
      // Retrowing to keep behavior consistent with previous crash.
      rethrow;
    }
  }

  Future<void> hideToTray() async {
    await _windowManager.hide();
  }
}
