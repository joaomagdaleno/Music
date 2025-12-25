import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'dart:math';

class SecurityService {
  static SecurityService? _instance;
  static SecurityService get instance =>
      _instance ??= SecurityService._internal();
  static set instance(SecurityService value) => _instance = value;
  static void resetInstance() => _instance = null;

  SecurityService._internal();

  final _storage = const FlutterSecureStorage();

  // Cache for the master key to avoid repeated secure storage reads
  encrypt.Key? _masterKey;

  Future<void> init() async {
    await _getOrCreateMasterKey();
  }

  Future<encrypt.Key> _getOrCreateMasterKey() async {
    if (_masterKey != null) {
      return _masterKey!;
    }

    String? keyString = await _storage.read(key: 'master_encryption_key');
    if (keyString == null) {
      // Generate a new 32-byte key
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      keyString = base64Url.encode(values);
      await _storage.write(key: 'master_encryption_key', value: keyString);
    }

    _masterKey = encrypt.Key.fromBase64(keyString);
    return _masterKey!;
  }

  /// Encrypts a string (e.g. for database fields)
  Future<String> encryptString(String plainText) async {
    final key = await _getOrCreateMasterKey();
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Combine IV and encrypted data for storage
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts a string
  Future<String> decryptString(String encryptedData) async {
    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        return encryptedData;
      }

      final key = await _getOrCreateMasterKey();
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (e) {
      return encryptedData; // Return original if decryption fails
    }
  }

  /// Specialized key for the Vault (can be reset via 2FA)
  Future<void> setupVaultPassword(String password) async {
    // We derive a key from the password or simply store the password securely
    // For simplicity in recovery, we'll store the vault key encrypted by the master key
    // but protected by the user's knowledge of the password.
    final vaultKey = encrypt.Key.fromSecureRandom(32).base64;
    await _storage.write(key: 'vault_internal_key', value: vaultKey);
    await _storage.write(
        key: 'vault_password_hash', value: _hashPassword(password));
  }

  String _hashPassword(String password) {
    // Simple hash for demo, in production use stronger KDF like Argon2
    final hash = base64Url.encode(utf8.encode(password));
    return hash.length > 20 ? hash.substring(0, 20) : hash;
  }

  Future<bool> unlockVault(String password) async {
    final storedHash = await _storage.read(key: 'vault_password_hash');
    return storedHash == _hashPassword(password);
  }

  Future<void> resetVaultPassword(String newPassword) async {
    // This would be called after a successful 2FA recovery flow
    await _storage.write(
        key: 'vault_password_hash', value: _hashPassword(newPassword));
  }

  Future<void> logout() async {
    _masterKey = null;
    await _storage.deleteAll();
  }
}
