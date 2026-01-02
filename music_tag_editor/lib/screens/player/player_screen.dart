import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/screens/player/views/fluent_player_view.dart';
import 'package:music_tag_editor/screens/player/views/material_player_view.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/widgets/duo_matching_dialog.dart';
import 'package:music_tag_editor/widgets/cast_dialog.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  bool _isFluent(BuildContext context) {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.windows ||
           platform == TargetPlatform.linux ||
           platform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    if (_isFluent(context)) {
      return FluentPlayerView(
        onShowSleepTimer: _showSleepTimerDialog,
        onShowQueue: _showQueueSheet,
        onShowDuoMatching: _showDuoMatchingDialog,
        onShowCast: _showCastDialog,
      );
    }

    return MaterialPlayerView(
      onShowSleepTimer: _showSleepTimerDialog,
      onShowQueue: _showQueueSheet,
      onShowDuoMatching: _showDuoMatchingDialog,
      onShowCast: _showCastDialog,
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temporizador (Sleep Timer)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('Desligar'), onTap: () { PlaybackService.instance.cancelSleepTimer(); Navigator.pop(context); }),
            ListTile(title: const Text('15 minutos'), onTap: () { PlaybackService.instance.setSleepTimer(const Duration(minutes: 15)); Navigator.pop(context); }),
            ListTile(title: const Text('30 minutos'), onTap: () { PlaybackService.instance.setSleepTimer(const Duration(minutes: 30)); Navigator.pop(context); }),
            ListTile(title: const Text('60 minutos'), onTap: () { PlaybackService.instance.setSleepTimer(const Duration(minutes: 60)); Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }

  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => const QueueSheet());
  }

  void _showDuoMatchingDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const DuoMatchingDialog());
  }

  void _showCastDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const CastDialog());
  }
}
