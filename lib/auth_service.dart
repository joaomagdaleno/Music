import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'security_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  /// Sends a password reset email. This is the first step for 2FA/Email recovery.
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint("Reset email error: $e");
      return false;
    }
  }

  /// Flow for recovering the Vault password using the authenticated session.
  /// This ensures that if a user has access to their email/account via 2FA,
  /// they can reset the local vault password.
  Future<bool> recoverVaultAccess(String email, String newVaultPassword) async {
    // 1. Ensure user is authenticated (they should be after logging in or via reset flow)
    if (_user == null || _user!.email != email) { return false; }

    // 2. Reset the vault password in SecurityService
    try {
      await SecurityService.instance.resetVaultPassword(newVaultPassword);
      return true;
    } catch (e) {
      return false;
    }
  }
}
