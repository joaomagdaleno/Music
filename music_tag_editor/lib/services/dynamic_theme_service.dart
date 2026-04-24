import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class DynamicThemeService extends ChangeNotifier {
  static final DynamicThemeService _instance = DynamicThemeService._internal();
  static DynamicThemeService get instance => _instance;

  DynamicThemeService._internal();

  Color _primaryColor = Colors.deepPurple;
  Color _secondaryColor = Colors.tealAccent;

  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;

  Future<void> updateThemeFromImage(Uint8List imageBytes) async {
    try {
      final imageProvider = MemoryImage(imageBytes);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 10,
      );

      final dominantColor = paletteGenerator.dominantColor?.color;
      final vibrantColor = paletteGenerator.vibrantColor?.color;
      final darkVibrantColor = paletteGenerator.darkVibrantColor?.color;
      final lightVibrantColor = paletteGenerator.lightVibrantColor?.color;
      final mutedColor = paletteGenerator.mutedColor?.color;

      // Logica de escolha: Preferir vibrant, senao dominant, senao default
      Color newPrimary = dominantColor ?? Colors.deepPurple;
      Color newSecondary = vibrantColor ?? lightVibrantColor ?? darkVibrantColor ?? mutedColor ?? Colors.tealAccent;

      // Garantir que não são as mesmas (para contraste)
      if (newPrimary.value == newSecondary.value) {
        newSecondary = Colors.tealAccent;
      }

      if (_primaryColor != newPrimary || _secondaryColor != newSecondary) {
        _primaryColor = newPrimary;
        _secondaryColor = newSecondary;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao atualizar tema: $e');
    }
  }

  void resetTheme() {
    if (_primaryColor != Colors.deepPurple || _secondaryColor != Colors.tealAccent) {
      _primaryColor = Colors.deepPurple;
      _secondaryColor = Colors.tealAccent;
      notifyListeners();
    }
  }
}
