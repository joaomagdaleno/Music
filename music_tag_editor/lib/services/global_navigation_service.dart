import 'package:flutter/material.dart';
import 'package:music_tag_editor/models/persona_model.dart';

class GlobalNavigationService extends ChangeNotifier {
  static GlobalNavigationService _instance = GlobalNavigationService._();
  static GlobalNavigationService get instance => _instance;

  static void resetInstance() {
    // _instance.dispose(); // ChangeNotifier.dispose renders it unusable, do not dispose before replacement if possible, or just replace.
    // Actually, if we dispose the old one, any listeners attached to it might complain if they try to use it?
    // But resetInstance is for tests.
    _instance = GlobalNavigationService._();
  }

  GlobalNavigationService._();

  int _mainIndex = 0;
  int get mainIndex => _mainIndex;

  final Map<AppPersona, int> _personaSubIndices = {
    AppPersona.librarian: 0,
    AppPersona.host: 0,
    AppPersona.artisan: 0,
  };

  int getSubIndex(AppPersona persona) => _personaSubIndices[persona] ?? 0;

  void setMainIndex(int index) {
    if (_mainIndex == index) return;
    _mainIndex = index;
    notifyListeners();
  }

  void setSubIndex(AppPersona persona, int subIndex) {
    if (_personaSubIndices[persona] == subIndex) return;
    _personaSubIndices[persona] = subIndex;
    notifyListeners();
  }

  /// Helper to navigate to a specific persona and tab.
  void navigateToPersonaTab(AppPersona persona, int tabIndex) {
    // 2 is typically the base index for personas in AppShell (Bibliotecário)
    // but we should probably use a more robust logic since personas are dynamic.
    // Index 2 = Librarian, 3 = Host, 4 = Artisan in current AppShell structure.
    int mainIdx = 0;
    switch (persona) {
      case AppPersona.librarian:
        mainIdx = 2;
        break;
      case AppPersona.host:
        mainIdx = 3;
        break;
      case AppPersona.artisan:
        mainIdx = 4;
        break;
    }

    setSubIndex(persona, tabIndex);
    setMainIndex(mainIdx);
  }
}
