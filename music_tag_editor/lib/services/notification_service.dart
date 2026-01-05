import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Shows a notification appropriate for the current platform.
  /// [context] is required to find the overlay or scaffold.
  /// [message] is the text to display.
  /// [severity] maps to Fluent UI severities (info, warning, error, success).
  void show(
    BuildContext context,
    String message, {
    NotificationSeverity severity = NotificationSeverity.info,
  }) {
    final isFluent = _isFluentPlatform;

    if (isFluent) {
      _showFluent(context, message, severity);
    } else {
      _showMaterial(context, message, severity);
    }
  }

  bool get _isFluentPlatform {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;
  }

  void _showFluent(
      BuildContext context, String message, NotificationSeverity severity) {
    fluent.displayInfoBar(context, builder: (context, close) => fluent.InfoBar(
          title: Text(message),
          severity: _mapSeverityToFluent(severity),
          onClose: close,
        ));
  }

  void _showMaterial(
      BuildContext context, String message, NotificationSeverity severity) {
    // Check if ScaffoldMessenger is available
    final messenger = ScaffoldMessenger.of(context);
    
    Color? backgroundColor;
    switch (severity) {
      case NotificationSeverity.error:
        backgroundColor = Colors.red;
        break;
      case NotificationSeverity.success:
        backgroundColor = Colors.green;
        break;
      case NotificationSeverity.warning:
        backgroundColor = Colors.orange;
        break;
      case NotificationSeverity.info:
        backgroundColor = null; // Default theme
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  fluent.InfoBarSeverity _mapSeverityToFluent(NotificationSeverity severity) {
    switch (severity) {
      case NotificationSeverity.info:
        return fluent.InfoBarSeverity.info;
      case NotificationSeverity.warning:
        return fluent.InfoBarSeverity.warning;
      case NotificationSeverity.error:
        return fluent.InfoBarSeverity.error;
      case NotificationSeverity.success:
        return fluent.InfoBarSeverity.success;
    }
  }
}

enum NotificationSeverity {
  info,
  warning,
  error,
  success,
}
