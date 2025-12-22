import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class DesktopIntegrationService {
  static final DesktopIntegrationService instance =
      DesktopIntegrationService._internal();
  DesktopIntegrationService._internal();

  final SystemTray _systemTray = SystemTray();

  Future<void> init() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) { return; }

    await windowManager.ensureInitialized();

    const String iconPath = 'windows/runner/resources/app_icon.ico';

    await _systemTray.initSystemTray(
      iconPath: iconPath,
      title: "Music App",
    );

    // Create the menu
    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
          label: 'Mostrar', onClicked: (menuItem) => windowManager.show()),
      MenuItemLabel(
          label: 'Ocultar', onClicked: (menuItem) => windowManager.hide()),
      MenuSeparator(),
      MenuItemLabel(
          label: 'Sair', onClicked: (menuItem) => windowManager.close()),
    ]);

    await _systemTray.setContextMenu(menu);

    // Handle events
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == 'leftClick' || eventName == 'click') {
        Platform.isWindows
            ? windowManager.show()
            : _systemTray.popUpContextMenu();
      } else if (eventName == 'rightClick') {
        Platform.isWindows
            ? _systemTray.popUpContextMenu()
            : windowManager.show();
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

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  Future<void> hideToTray() async {
    await windowManager.hide();
  }
}
