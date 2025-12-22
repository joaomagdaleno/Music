import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();

  Color _primaryColor = Colors.blue;
  Color get primaryColor => _primaryColor;

  Future<void> updateThemeFromImage(String? imageUrl) async {
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
