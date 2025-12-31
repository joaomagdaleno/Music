import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:file_picker/file_picker.dart';
import 'package:music_tag_editor/services/backup_service.dart';
import 'package:music_tag_editor/screens/backup/views/fluent_backup_view.dart';
import 'package:music_tag_editor/screens/backup/views/material_backup_view.dart';

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
      final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Escolha onde salvar o backup');
      if (dir != null) {
        final path = await BackupService.instance.createBackup(dir);
        setState(() => _lastBackupPath = path);
        _showSuccess('Backup criado com sucesso!');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, dialogTitle: 'Selecione o arquivo de backup');
      if (result != null && result.files.single.path != null) {
        await BackupService.instance.restoreBackup(result.files.single.path!);
        _showSuccess('Backup restaurado com sucesso!');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.windows || platform == TargetPlatform.macOS || platform == TargetPlatform.linux) {
      fluent.displayInfoBar(context, builder: (_, close) => fluent.InfoBar(title: Text(message), severity: fluent.InfoBarSeverity.success, onClose: close));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentBackupView(isLoading: _isLoading, lastBackupPath: _lastBackupPath, onCreateBackup: _createBackup, onRestoreBackup: _restoreBackup);
      default:
        return MaterialBackupView(isLoading: _isLoading, lastBackupPath: _lastBackupPath, onCreateBackup: _createBackup, onRestoreBackup: _restoreBackup);
    }
  }
}
