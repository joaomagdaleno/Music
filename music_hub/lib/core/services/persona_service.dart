import 'package:flutter/material.dart';
import '../models/persona_model.dart';
import 'database_service.dart';

class PersonaService extends ChangeNotifier {
  static final PersonaService instance = PersonaService._();
  PersonaService._();

  AppPersona _activePersona = AppPersona.librarian;
  AppPersona get activePersona => _activePersona;

  /// Inicializa o serviço, possivelmente carregando a persona salva.
  Future<void> init() async {
    final savedPersona =
        await DatabaseService.instance.getSetting('active_persona');
    if (savedPersona != null) {
      try {
        _activePersona = AppPersona.values.firstWhere(
          (e) => e.name == savedPersona,
          orElse: () => AppPersona.librarian,
        );
      } catch (_) {
        _activePersona = AppPersona.librarian;
      }
    }
    notifyListeners();
  }

  void setPersona(AppPersona persona) {
    if (_activePersona == persona) return;
    _activePersona = persona;
    DatabaseService.instance.saveSetting('active_persona', persona.name);
    notifyListeners();
  }

  static void resetInstance() {
    instance._activePersona = AppPersona.librarian;
  }
}
