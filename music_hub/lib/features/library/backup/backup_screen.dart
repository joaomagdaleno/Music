import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:music_hub/core/services/backup_service.dart';
import 'package:music_hub/features/library/backup/views/fluent_backup_view.dart';
import 'package:music_hub/features/library/backup/views/material_backup_view.dart';

/// BackupScreen controller - platform-adaptive
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;
  String? _lastBackupPath;

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      if (!await _checkPermission()) return;

      String? dir;

      // On Android 11+, FilePicker may return URIs that dart:io can't use.
      // Fallback to a safe default directory if needed.
      if (Platform.isAndroid) {
        // Use a default path that is always accessible on Android
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          dir = downloadsDir.path;
        } else {
          _showSuccess('Não foi possível acessar a pasta de Downloads.');
          return;
        }
      } else {
        dir = await FilePicker.platform
            .getDirectoryPath(dialogTitle: 'Escolha onde salvar o backup');
      }

      if (dir != null) {
        try {
          final path = await BackupService.instance.createBackup(dir);
          setState(() => _lastBackupPath = path);
          _showSuccess('Backup criado com sucesso!');
        } on FileSystemException catch (e) {
          debugPrint('❌ BackupScreen: FileSystemException - $e');
          _showSuccess('Erro ao criar backup: caminho inacessível.');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => _isLoading = true);
    try {
      if (!await _checkPermission()) return;
      final result = await FilePicker.platform.pickFiles(
          type: FileType.any, dialogTitle: 'Selecione o arquivo de backup');
      if (result != null && result.files.single.path != null) {
        await BackupService.instance.restoreBackup(result.files.single.path!);
        _showSuccess('Backup restaurado com sucesso!');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkPermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ (API 33+): Use granular media permissions
    // This is Play Store compliant - no need for MANAGE_EXTERNAL_STORAGE
    if (await Permission.audio.request().isGranted) {
      return true;
    }

    // Android 10 and below: Use legacy storage permission
    if (await Permission.storage.request().isGranted) {
      return true;
    }

    // Check if permanently denied
    if (await Permission.audio.isPermanentlyDenied ||
        await Permission.storage.isPermanentlyDenied) {
      _showSuccess('Permissão negada. Habilite nas configurações.');
      openAppSettings();
    }

    return false;
  }

  void _showSuccess(String message) {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux) {
      fluent.displayInfoBar(context,
          builder: (_, close) => fluent.InfoBar(
              title: Text(message),
              severity: fluent.InfoBarSeverity.success,
              onClose: close));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentBackupView(
            isLoading: _isLoading,
            lastBackupPath: _lastBackupPath,
            onCreateBackup: _createBackup,
            onRestoreBackup: _restoreBackup);
      default:
        return MaterialBackupView(
            isLoading: _isLoading,
            lastBackupPath: _lastBackupPath,
            onCreateBackup: _createBackup,
            onRestoreBackup: _restoreBackup);
    }
  }
}
