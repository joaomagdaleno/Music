import 'package:flutter/material.dart';
import 'package:music_tag_editor/models/filename_format.dart';
import 'package:music_tag_editor/screens/settings/views/fluent_settings_view.dart';
import 'package:music_tag_editor/screens/settings/views/material_settings_view.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/firebase_sync_service.dart';
import 'package:music_tag_editor/services/metadata_cleanup_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  FilenameFormat _selectedFormat = FilenameFormat.artistTitle;
  int _crossfadeSeconds = 3;
  bool _ageBypass = false;
  bool _isLoading = true;

  bool get _isFluent {
    final platform = Theme.of(context).platform;
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
    
    // On Fluent, we might use InfoBar or ContentDialog, but ScaffolMessenger works for now 
    // or we can pass a callback that the view handles.
    // For simplicity, we keep ScaffoldMessenger as it works on FluentApp too (usually).
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preference saved!')),
    );
  }

  Future<void> _cleanupLibrary() async {
    setState(() => _isLoading = true);
    final count = await MetadataCleanupService.instance.cleanupLibrary();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count músicas foram polidas e organizadas!')),
      );
    }
  }

  Future<void> _enableCloudSync() async {
    setState(() => _isLoading = true);
    final success = await FirebaseSyncService.instance.enableSync();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Sincronização ativada!'
              : 'Erro ao ativar sincronização'),
        ),
      );
    }
  }

  Future<void> _pullFromCloud() async {
    setState(() => _isLoading = true);
    final count = await FirebaseSyncService.instance.pullFromCloud();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count itens sincronizados!')),
      );
    }
  }

  Future<void> _saveCrossfade(int validSeconds) async {
    await _dbService.saveCrossfadeDuration(validSeconds);
    PlaybackService.instance.updateCrossfadeDuration(
        Duration(seconds: validSeconds));
  }
  
  Future<void> _saveAgeBypass(bool val) async {
      setState(() => _ageBypass = val);
      await _dbService.saveAgeBypass(val);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFluent) {
      return FluentSettingsView(
        isLoading: _isLoading,
        selectedFormat: _selectedFormat,
        crossfadeSeconds: _crossfadeSeconds,
        ageBypass: _ageBypass,
        onFormatChanged: (val) {
          if (val != null) _saveFormat(val);
        },
        onCrossfadeChanged: (val) {
          setState(() => _crossfadeSeconds = val.toInt());
        },
        onCrossfadeSaved: _saveCrossfade,
        onAgeBypassChanged: (val) async {
             if (val) {
                // Confirm logic usually needs context/dialog.
                // We'll simplisticly toggle it here, or we'd move the dialog logic to the View
                // OR we move the dialog logic here but we need a way to show dialog from Controller
                // For now, simpler implementation: prompt logic was in View in previous legacy code
                // But generally logic in Controller.
                // We can let the View handle the confirmation UI and then call this callback only if confirmed.
                // Let's assume the View handles the confirmation for UI purity.
                // Actually, logic was: "If checking true, show dialog".
                // We'll update _ageBypass after callback.
              }
            _saveAgeBypass(val);
        },
        onCleanupLibrary: _cleanupLibrary,
        onEnableCloudSync: _enableCloudSync,
        onPullFromCloud: _pullFromCloud,
      );
    }

    return MaterialSettingsView(
      isLoading: _isLoading,
      selectedFormat: _selectedFormat,
      crossfadeSeconds: _crossfadeSeconds,
      ageBypass: _ageBypass,
      onFormatChanged: (val) {
        if (val != null) _saveFormat(val);
      },
      onCrossfadeChanged: (val) => setState(() => _crossfadeSeconds = val.toInt()),
      onCrossfadeSaved: _saveCrossfade,
      onAgeBypassChanged: (val) => _saveAgeBypass(val),
      onCleanupLibrary: _cleanupLibrary,
      onEnableCloudSync: _enableCloudSync,
      onPullFromCloud: _pullFromCloud,
    );
  }
}
