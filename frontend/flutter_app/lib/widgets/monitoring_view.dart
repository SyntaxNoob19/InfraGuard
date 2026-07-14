import 'package:flutter/material.dart';
import '../providers/threat_provider.dart';
import '../theme/app_theme.dart';
import 'log_section.dart';

/// The "System Secure" monitoring state — shown when no active threats exist.
class MonitoringView extends StatelessWidget {
  final ThreatProvider provider;

  const MonitoringView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final state = provider.appState;
    final agents   = state?.activeAgents ?? 0;
    final resolved = state?.resolvedThreats.length ?? 0;
    final payloads = provider.payloadsScanned;
    final logs     = state?.recentLogs ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.pad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SecureHero(agents: agents),
              const SizedBox(height: 24),
              _StatsRow(
                payloads: payloads,
                blocked: resolved,
                agents: agents,
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
}

// ── Secure hero ────────────────────────────────────────────────────────────────

class _SecureHero extends StatelessWidget {
  final int agents;

  const _SecureHero({required this.agents});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Status icon with gradient ring
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.green.withAlpha(35),
                AppTheme.green.withAlpha(8),
              ],
            ),
            border: Border.all(color: AppTheme.green.withAlpha(80), width: 1.5),
          ),
          child: const Icon(Icons.shield_rounded,
              color: AppTheme.green, size: 52),
        ),
        const SizedBox(height: 20),
        Text(
          'System Secure',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          agents > 0
              ? 'Monitoring $agents active AI ${agents == 1 ? 'agent' : 'agents'}'
              : 'Waiting for agents to connect...',
          style: const TextStyle(
            fontSize: 15,
            color: AppTheme.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'All runtime actions are within policy',
          style: const TextStyle(fontSize: 13, color: AppTheme.mutedText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int payloads;
  final int blocked;
  final int agents;

  const _StatsRow({
    required this.payloads,
    required this.blocked,
    required this.agents,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(value: '$payloads', label: 'Payloads\nScanned', color: AppTheme.blue),
        const SizedBox(width: 10),
        _StatChip(value: '$blocked', label: 'Threats\nBlocked', color: AppTheme.red),
        const SizedBox(width: 10),
        _StatChip(value: '$agents', label: 'Active\nAgents', color: AppTheme.green),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.mutedText, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
