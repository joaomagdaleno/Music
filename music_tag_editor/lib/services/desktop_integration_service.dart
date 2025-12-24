import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

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

    await _windowManager.ensureInitialized();

    const String iconPath = 'windows/runner/resources/app_icon.ico';

    await _systemTray.initSystemTray(
      iconPath: iconPath,
      title: "Music App",
    );

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

    await _windowManager.waitUntilReadyToShow(windowOptions, () async {
      await _windowManager.show();
      await _windowManager.focus();
    });
  }

  Future<void> hideToTray() async {
    await _windowManager.hide();
  }
}
