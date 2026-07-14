import 'package:flutter/material.dart';
import '../providers/threat_provider.dart';
import '../theme/app_theme.dart';

/// Animated connection status chip for the AppBar.
class ConnectionBadge extends StatelessWidget {
  final ConnectionStatus status;

  const ConnectionBadge({super.key, required this.status});

  Color get _color => switch (status) {
        ConnectionStatus.connected => AppTheme.green,
        ConnectionStatus.polling   => AppTheme.amber,
        ConnectionStatus.offline   => AppTheme.red,
        ConnectionStatus.loading   => AppTheme.blue,
      };

  IconData get _icon => switch (status) {
        ConnectionStatus.connected => Icons.cloud_done_rounded,
        ConnectionStatus.polling   => Icons.sync_rounded,
        ConnectionStatus.offline   => Icons.cloud_off_rounded,
        ConnectionStatus.loading   => Icons.sync_rounded,
      };

  String get _label => switch (status) {
        ConnectionStatus.connected => 'Connected',
        ConnectionStatus.polling   => 'Syncing',
        ConnectionStatus.offline   => 'Offline',
        ConnectionStatus.loading   => 'Connecting',
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withAlpha(22),
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
        border: Border.all(color: _color.withAlpha(90), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 13, color: _color),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
