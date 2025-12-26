import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/security_service.dart';

class AuthService extends ChangeNotifier {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._internal();

  @visibleForTesting
  static set instance(AuthService mock) => _instance = mock;

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  AuthService._internal({FirebaseAuth? auth, SecurityService? securityService})
      : _auth = auth ?? FirebaseAuth.instance,
        _securityService = securityService ?? SecurityService.instance;

  @visibleForTesting
  factory AuthService.test(
      {FirebaseAuth? auth, SecurityService? securityService}) {
    return AuthService._internal(auth: auth, securityService: securityService);
  }

  final FirebaseAuth _auth;
  final SecurityService _securityService;
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  void init() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      debugPrint("Login error: $e");
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return true;
    } catch (e) {
      debugPrint("Registration error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint("Reset email error: $e");
      return false;
    }
  }

  Future<bool> recoverVaultAccess(String email, String newVaultPassword) async {
    if (_user == null || _user!.email != email) {
      return false;
    }

    try {
      await _securityService.resetVaultPassword(newVaultPassword);
      return true;
    } catch (e) {
      return false;
    }
  }
}
