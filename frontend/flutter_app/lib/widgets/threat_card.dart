import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

/// The hero Threat Card — shows all incident details cleanly.
/// All text wraps; no overflow.
class ThreatCard extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onViewImpact;

  const ThreatCard({
    super.key,
    required this.incident,
    required this.onViewImpact,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = AppTheme.severityColor(incident.severity);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient header ───────────────────────────────────────────────
          _CardHeader(severity: incident.severity, color: severityColor),

          // ── Detail rows ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.cardPad, 16, AppTheme.cardPad, AppTheme.cardPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Agent', value: incident.agentId),
                _DetailRow(label: 'Method', value: incident.method),
                _DetailRow(label: 'Rule', value: incident.matchedRule),
                _DetailRow(label: 'Reason', value: incident.reason),
                _DetailRow(label: 'Time', value: _formatTime(incident.timestamp)),
                _DetailRow(
                  label: 'Incident ID',
                  value: incident.incidentId,
                  mono: true,
                ),
                const SizedBox(height: 12),
                // View Impact link
                GestureDetector(
                  onTap: onViewImpact,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.open_in_new_rounded,
                          size: 14, color: AppTheme.blue),
                      const SizedBox(width: 6),
                      Text(
                        'View Impact Analysis',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.blue,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      return '$h:$m:$s  (${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')})';
    } catch (_) {
      return raw;
    }
  }
}

// ── Card header with gradient background ────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final String severity;
  final Color color;

  const _CardHeader({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.cardPad, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(50), color.withAlpha(18)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius),
          topRight: Radius.circular(AppTheme.radius),
        ),
        border: Border(bottom: BorderSide(color: color.withAlpha(60), width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Threat Detected',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          _SeverityChip(severity: severity, color: color),
        ],
      ),
    );
  }
}

// ── Severity chip ────────────────────────────────────────────────────────────

class _SeverityChip extends StatelessWidget {
  final String severity;
  final Color color;

  const _SeverityChip({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
        border: Border.all(color: color.withAlpha(100), width: 1),
      ),
      child: Text(
        severity,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Detail row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _DetailRow({required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: mono
                ? SelectableText(
                    value,
                    style: AppTheme.mono(12, color: AppTheme.secondaryText),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryText,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
