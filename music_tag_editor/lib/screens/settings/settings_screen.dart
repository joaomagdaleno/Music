import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_tag_editor/models/filename_format.dart';
import 'package:music_tag_editor/screens/settings/views/fluent_settings_view.dart';
import 'package:music_tag_editor/screens/settings/views/material_settings_view.dart';
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/firebase_sync_service.dart';
import 'package:music_tag_editor/services/metadata_cleanup_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/screens/login/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  final AuthService _authService = AuthService.instance;
  FilenameFormat _selectedFormat = FilenameFormat.artistTitle;
  int _crossfadeSeconds = 3;
  bool _ageBypass = false;
  bool _isLoading = true;

  bool get _isFluent {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final format = await _dbService.loadFilenameFormat();
    final crossfade = await _dbService.loadCrossfadeDuration();
    final ageBypass = await _dbService.loadAgeBypass();
    if (mounted) {
      setState(() {
        _selectedFormat = format;
        _crossfadeSeconds = crossfade;
        _ageBypass = ageBypass;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFormat(FilenameFormat format) async {
    setState(() => _selectedFormat = format);
    await _dbService.saveFilenameFormat(format);
    if (!mounted) return;

    _showNotification('Preferência salva!');
  }

  Future<void> _cleanupLibrary() async {
    setState(() => _isLoading = true);
    final count = await MetadataCleanupService.instance.cleanupLibrary();
    if (mounted) {
      setState(() => _isLoading = false);
      _showNotification('$count músicas foram polidas e organizadas!');
    }
  }

  Future<void> _enableCloudSync() async {
    if (!_authService.isAuthenticated) {
      _navigateToLogin();
      return;
    }
    setState(() => _isLoading = true);
    final success = await FirebaseSyncService.instance.enableSync();
    if (mounted) {
      setState(() => _isLoading = false);
      _showNotification(success
          ? 'Sincronização ativada!'
          : 'Erro ao ativar sincronização');
    }
  }

  Future<void> _pullFromCloud() async {
    if (!_authService.isAuthenticated) {
      _navigateToLogin();
      return;
    }
    setState(() => _isLoading = true);
    final count = await FirebaseSyncService.instance.pullFromCloud();
    if (mounted) {
      setState(() => _isLoading = false);
      _showNotification('$count itens sincronizados!');
    }
  }

  void _navigateToLogin() {
    Navigator.of(context)
        .push(
          _isFluent
              ? fluent.FluentPageRoute(builder: (_) => const LoginScreen())
              : MaterialPageRoute(builder: (_) => const LoginScreen()),
        )
        .then((_) => setState(() {})); // Refresh state after return
  }

  Future<void> _logout() async {
    await _authService.logout();
    setState(() {});
  }

  Future<void> _saveCrossfade(int validSeconds) async {
    await _dbService.saveCrossfadeDuration(validSeconds);
    PlaybackService.instance
        .updateCrossfadeDuration(Duration(seconds: validSeconds));
  }

  Future<void> _saveAgeBypass(bool val) async {
    setState(() => _ageBypass = val);
    await _dbService.saveAgeBypass(val);
  }

  void _showNotification(String message) {
    if (_isFluent) {
      fluent.displayInfoBar(context, builder: (context, close) {
        return fluent.InfoBar(
          title: Text(message),
          severity: fluent.InfoBarSeverity.success,
          onClose: close,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFluent) {
      return FluentSettingsView(
        isLoading: _isLoading,
        selectedFormat: _selectedFormat,
        crossfadeSeconds: _crossfadeSeconds,
        ageBypass: _ageBypass,
        isAuthenticated: _authService.isAuthenticated,
        onFormatChanged: (val) {
          if (val != null) _saveFormat(val);
        },
        onCrossfadeChanged: (val) {
          setState(() => _crossfadeSeconds = val.toInt());
        },
        onCrossfadeSaved: _saveCrossfade,
        onAgeBypassChanged: (val) async {
          _saveAgeBypass(val);
        },
        onCleanupLibrary: _cleanupLibrary,
        onEnableCloudSync: _enableCloudSync,
        onPullFromCloud: _pullFromCloud,
        onLogin: _navigateToLogin,
        onLogout: _logout,
      );
    }

    return MaterialSettingsView(
      isLoading: _isLoading,
      selectedFormat: _selectedFormat,
      crossfadeSeconds: _crossfadeSeconds,
      ageBypass: _ageBypass,
      isAuthenticated: _authService.isAuthenticated,
      onFormatChanged: (val) {
        if (val != null) _saveFormat(val);
      },
      onCrossfadeChanged: (val) =>
          setState(() => _crossfadeSeconds = val.toInt()),
      onCrossfadeSaved: _saveCrossfade,
      onAgeBypassChanged: (val) => _saveAgeBypass(val),
      onCleanupLibrary: _cleanupLibrary,
      onEnableCloudSync: _enableCloudSync,
      onPullFromCloud: _pullFromCloud,
      onLogin: _navigateToLogin,
      onLogout: _logout,
    );
  }
}
