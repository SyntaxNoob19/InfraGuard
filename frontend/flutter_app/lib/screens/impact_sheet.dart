import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

/// Impact Analysis BottomSheet.
/// Opens when the user taps "View Impact Analysis" on a threat card.
/// Since the backend does not expose an impact endpoint, shows a professional
/// placeholder with a clear "not available" message per the spec.
class ImpactSheet extends StatelessWidget {
  final IncidentModel incident;

  const ImpactSheet({super.key, required this.incident});

  static void show(BuildContext context, IncidentModel incident) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.elevatedCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.dialogRadius),
        ),
      ),
      builder: (_) => ImpactSheet(incident: incident),
    );
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = AppTheme.severityColor(incident.severity);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppTheme.pad,
          20,
          AppTheme.pad,
          MediaQuery.of(context).viewInsets.bottom + AppTheme.pad,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: severityColor, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Predicted Impact',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Incident ${incident.incidentId.substring(0, 8)}...',
              style: AppTheme.mono(11, color: AppTheme.mutedText),
            ),
            const SizedBox(height: 20),
            const Divider(color: AppTheme.divider),
            const SizedBox(height: 16),

            // Placeholder rows
            _ImpactRow(label: 'Impact Summary',
                value: 'Analysis not available for this incident.'),
            _ImpactRow(label: 'Files Affected',  value: 'Not available'),
            _ImpactRow(label: 'Resources',        value: 'Not available'),
            _ImpactRow(label: 'Risk Level',
                value: incident.severity,
                valueColor: severityColor),
            _ImpactRow(label: 'Estimated Result',
                value: 'Blocked by InfraGuard proxy'),
            const SizedBox(height: 20),

            // Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.blue.withAlpha(15),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: AppTheme.blue.withAlpha(60), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.blue, size: 16),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Full impact analysis requires the backend impact endpoint (planned for Phase 6). '
                      'The proxy already prevented execution — no files were modified.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ImpactRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.mutedText, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? AppTheme.secondaryText,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
