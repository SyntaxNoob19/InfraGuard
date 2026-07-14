import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../providers/threat_provider.dart';
import '../screens/impact_sheet.dart';
import '../theme/app_theme.dart';
import 'action_buttons.dart';
import 'log_section.dart';
import 'payload_viewer.dart';
import 'threat_card.dart';

/// The "Threat Detected" state — shows the threat card, payload, action buttons, and log.
class ThreatView extends StatelessWidget {
  final ThreatProvider provider;
  final void Function(BuildContext, ThreatProvider, IncidentModel, String) onAction;

  const ThreatView({
    super.key,
    required this.provider,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final incident = provider.appState!.activeThreats.first;
    final logs = provider.appState?.recentLogs ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.pad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ThreatBanner(),
              const SizedBox(height: 16),
              ThreatCard(
                incident: incident,
                onViewImpact: () => ImpactSheet.show(context, incident),
              ),
              const SizedBox(height: 12),
              PayloadViewer(payload: incident.payload),
              const SizedBox(height: 20),
              ActionButtons(
                isResolving: provider.isResolving,
                onAction: (action) => onAction(context, provider, incident, action),
                onQuarantineRequest: () =>
                    _confirmQuarantine(context, provider, incident),
              ),
              const SizedBox(height: 28),
              LogSection(logs: logs),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmQuarantine(
    BuildContext context,
    ThreatProvider provider,
    IncidentModel incident,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dangerous_rounded, color: AppTheme.red, size: 22),
            SizedBox(width: 10),
            Text('Confirm Quarantine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: const Text(
          'This will forcefully terminate the agent subprocess.\n\nThe process cannot be resumed after quarantine.',
          style: TextStyle(fontSize: 14, color: AppTheme.secondaryText, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.btnRadius)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onAction(context, provider, incident, 'QUARANTINE');
            },
            child: const Text('Quarantine', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Threat banner ─────────────────────────────────────────────────────────────

class _ThreatBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.red.withAlpha(50), AppTheme.red.withAlpha(18)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.red.withAlpha(80), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Execution Paused',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.red,
                  ),
                ),
                Text(
                  'An AI agent attempted an unauthorized action. Admin review required.',
                  style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
