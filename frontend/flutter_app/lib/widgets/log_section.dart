import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import 'log_tile.dart';

/// Scrollable recent-logs section backed by real API data.
class LogSection extends StatelessWidget {
  final List<LogEntryModel> logs;

  const LogSection({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final reversed = logs.reversed.take(40).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.receipt_long_rounded,
          title: 'Recent Activity',
          badge: '${reversed.length}',
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.secondaryBg,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppTheme.divider, width: 1),
          ),
          child: reversed.isEmpty
              ? _EmptyLogs()
              : Column(
                  children: [
                    for (int i = 0; i < reversed.length; i++) ...[
                      LogTile(log: reversed[i]),
                      if (i < reversed.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _EmptyLogs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppTheme.cardPad),
      child: Center(
        child: Text(
          'Waiting for first intercepted payload...',
          style: TextStyle(color: AppTheme.mutedText, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Reusable section header with icon, title, and optional right badge.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;

  const _SectionHeader({required this.icon, required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.mutedText),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryText,
            letterSpacing: 0.8,
          ),
        ),
        if (badge != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.elevatedCard,
              borderRadius: BorderRadius.circular(AppTheme.chipRadius),
              border: Border.all(color: AppTheme.divider, width: 1),
            ),
            child: Text(badge!, style: const TextStyle(fontSize: 11, color: AppTheme.mutedText)),
          ),
        ],
      ],
    );
  }
}
