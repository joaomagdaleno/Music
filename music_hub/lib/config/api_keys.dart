/// Centralized API key configuration.
///
/// ⚠️ SECURITY WARNING:
/// - Do NOT commit real API keys to version control!
/// - For production, use environment variables or platform-specific secure storage:
///   - Android: EncryptedSharedPreferences or Android Keystore
///   - iOS: Keychain
///   - Windows: Windows Credential Manager
///   - Web: Environment variables at build time (--dart-define)
///
/// Example using dart-define:
/// ```bash
/// flutter build apk --dart-define=LASTFM_KEY=your_key_here
/// ```
/// Then access via: `const String.fromEnvironment('LASTFM_KEY')`
class ApiKeys {
  // Get your key at: https://www.last.fm/api/account/create
  static const String lastFmApiKey = 'YOUR_LASTFM_API_KEY';

  // Get your token at: https://genius.com/api-clients
  static const String geniusAccessToken = 'YOUR_GENIUS_ACCESS_TOKEN';
}
