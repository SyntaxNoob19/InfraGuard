import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

/// A single row in the recent-logs list, showing time | icon | message.
class LogTile extends StatelessWidget {
  final LogEntryModel log;

  const LogTile({super.key, required this.log});

  Color get _color => switch (log.type) {
        'WARNING' => AppTheme.amber,
        'ERROR'   => AppTheme.red,
        'SUCCESS' => AppTheme.green,
        'ADMIN'   => AppTheme.blue,
        _         => AppTheme.mutedText,
      };

  IconData get _icon => switch (log.type) {
        'WARNING' => Icons.warning_amber_rounded,
        'ERROR'   => Icons.cancel_rounded,
        'SUCCESS' => Icons.check_circle_rounded,
        'ADMIN'   => Icons.admin_panel_settings_rounded,
        _         => Icons.info_outline_rounded,
      };

  String get _time {
    try {
      final dt = DateTime.parse(log.timestamp).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      return '$h:$m:$s';
    } catch (_) {
      return '--:--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          SizedBox(
            width: 64,
            child: Text(
              _time,
              style: AppTheme.mono(11, color: AppTheme.mutedText),
            ),
          ),
          const SizedBox(width: 10),
          // Type icon
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(_icon, size: 15, color: _color),
          ),
          const SizedBox(width: 10),
          // Message
          Expanded(
            child: Text(
              log.message,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.secondaryText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
