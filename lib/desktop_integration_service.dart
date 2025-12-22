import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class DesktopIntegrationService {
  static final DesktopIntegrationService instance =
      DesktopIntegrationService._internal();
  DesktopIntegrationService._internal();

  final SystemTray _systemTray = SystemTray();
  final AppWindow _appWindow = AppWindow();

  Future<void> init() async {
    if (!Platform.isWindows) return;

    await windowManager.ensureInitialized();

    String path =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';
    // Ideally we should have an .ico for windows. For now assuming we might need to bundle one.
    // system_tray usually requires the icon to be in the built resources.
    // We'll use a placeholder or try to use a standard one if possible.
    // Note: system_tray acts on the compiled executable resources often.

    // We'll setup the tray with a default icon path.
    // Ensure you have an 'app_icon.ico' in your windows/runner/resources or similar if using native.
    // For flutter assets, system_tray might need full path or specific handling.
    // Let's assume standard behavior for now.

    const String iconPath = 'windows/runner/resources/app_icon.ico';

    await _systemTray.initSystemTray(
      title: "Music App",
      iconPath: iconPath,
    );

    // Create the menu
    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
          label: 'Mostrar', onClicked: (menuItem) => _appWindow.show()),
      MenuItemLabel(
          label: 'Ocultar', onClicked: (menuItem) => _appWindow.hide()),
      MenuSeparator(),
      MenuItemLabel(label: 'Sair', onClicked: (menuItem) => _appWindow.close()),
    ]);

    await _systemTray.setContextMenu(menu);

    // Handle left click on tray icon
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        Platform.isWindows ? _appWindow.show() : _systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        Platform.isWindows ? _systemTray.popUpContextMenu() : _appWindow.show();
      }
    });

    // Configure window manager to minimize to tray instead of closing (optional, usually done in main)
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
