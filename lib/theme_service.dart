import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'database_service.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();

  Color _primaryColor = Colors.blue;
  Color? _customColor;
  bool _useCustomColor = false;

  Color get primaryColor =>
      _useCustomColor && _customColor != null ? _customColor! : _primaryColor;

  bool get useCustomColor => _useCustomColor;
  Color? get customColor => _customColor;

  // Preset colors for quick selection
  static const List<Color> presetColors = [
    Colors.purple,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.red,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
  ];

  Future<void> init() async {
    final colorValue = await DatabaseService.instance.getSetting('customColor');
    final useCustom =
        await DatabaseService.instance.getSetting('useCustomColor');

    if (colorValue != null) {
      _customColor = Color(int.parse(colorValue));
    }
    _useCustomColor = useCustom == 'true';
    notifyListeners();
  }

  Future<void> setCustomColor(Color color) async {
    _customColor = color;
    _useCustomColor = true;
    await DatabaseService.instance
        .saveSetting('customColor', color.toARGB32().toString());
    await DatabaseService.instance.saveSetting('useCustomColor', 'true');
    notifyListeners();
  }

  Future<void> setAutoMode() async {
    _useCustomColor = false;
    await DatabaseService.instance.saveSetting('useCustomColor', 'false');
    notifyListeners();
  }

  Future<void> updateThemeFromImage(String? imageUrl) async {
    // Only update if in auto mode
    if (_useCustomColor) { return; }

    if (imageUrl == null) {
      _primaryColor = Colors.blue;
      notifyListeners();
      return;
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        maximumColorCount: 10,
      );

      _primaryColor = palette.dominantColor?.color ?? Colors.blue;
      notifyListeners();
    } catch (e) {
      debugPrint("Error extracting palette: $e");
      _primaryColor = Colors.blue;
      notifyListeners();
    }
  }
}
