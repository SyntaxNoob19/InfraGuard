import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../providers/threat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_badge.dart';
import '../widgets/monitoring_view.dart';
import '../widgets/threat_view.dart';
import 'settings_screen.dart';

/// The single root screen of InfraGuard.
/// Drives the four application states from live provider data.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Resolve current UI state from provider
  _AppState _resolveState(ThreatProvider p) {
    if (p.isLoading) return _AppState.connecting;
    if (!p.isConnected) return _AppState.offline;
    if (p.appState?.activeThreats.isNotEmpty ?? false) return _AppState.threat;
    return _AppState.monitoring;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.primaryBg,
        appBar: _buildAppBar(context),
        body: Consumer<ThreatProvider>(
          builder: (context, provider, _) {
            final state = _resolveState(provider);
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildState(context, provider, state),
            );
          },
        ),
        bottomNavigationBar: const _StatusFooter(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'InfraGuard Admin',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryText,
            ),
          ),
          const Text(
            'Zero Trust Runtime Protection',
            style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
          ),
        ],
      ),
      actions: [
        Consumer<ThreatProvider>(
          builder: (_, provider, __) => Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ConnectionBadge(
              status: provider.connectionStatus,
              clients: provider.appState?.connectedClients ?? 0,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: AppTheme.primaryText),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildState(BuildContext context, ThreatProvider provider, _AppState state) {
    return switch (state) {
      _AppState.connecting  => const _ConnectingView(key: ValueKey('connecting')),
      _AppState.offline     => _OfflineView(key: const ValueKey('offline'), provider: provider),
      _AppState.monitoring  => MonitoringView(key: const ValueKey('monitoring'), provider: provider),
      _AppState.threat      => ThreatView(
                                key: const ValueKey('threat'),
                                provider: provider,
                                onAction: _handleAction,
                              ),
    };
  }

  void _handleAction(
    BuildContext context,
    ThreatProvider provider,
    IncidentModel incident,
    String action,
  ) async {
    final success = await provider.resolve(incident.incidentId, action);
    if (!context.mounted) return;
    final msgs = {
      'ALLOW':         success ? 'Execution resumed. Action permitted.' : 'Failed to allow. Check connection.',
      'BLOCK_COMMAND': success ? 'Command blocked. Payload discarded.' : 'Failed to block. Check connection.',
      'QUARANTINE':    success ? 'Agent terminated. Process killed.' : 'Failed to quarantine. Check connection.',
    };
    AppTheme.showSnack(context,
        message: msgs[action] ?? 'Action sent.', success: success);
  }
}

// ── Application state enum ────────────────────────────────────────────────────

enum _AppState { connecting, offline, monitoring, threat }

// ── Connecting view ───────────────────────────────────────────────────────────

class _ConnectingView extends StatelessWidget {
  const _ConnectingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppTheme.blue,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connecting',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Establishing secure connection to the proxy...',
              style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Offline view ──────────────────────────────────────────────────────────────

class _OfflineView extends StatelessWidget {
  final ThreatProvider provider;

  const _OfflineView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final heartbeat = provider.lastHeartbeat;
    final lastSeen = heartbeat != null
        ? '${heartbeat.hour.toString().padLeft(2, '0')}:${heartbeat.minute.toString().padLeft(2, '0')}:${heartbeat.second.toString().padLeft(2, '0')}'
        : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.red.withAlpha(15),
                border: Border.all(color: AppTheme.red.withAlpha(70), width: 1.5),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppTheme.red, size: 40),
            ),
            const SizedBox(height: 24),
            Text('Proxy Offline', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            if (lastSeen != null) ...[
              Text(
                'Last heartbeat: $lastSeen',
                style: const TextStyle(fontSize: 14, color: AppTheme.secondaryText),
              ),
              const SizedBox(height: 4),
            ],
            const Text(
              'Waiting for proxy to reconnect...',
              style: TextStyle(fontSize: 13, color: AppTheme.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppTheme.blue.withAlpha(180),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Auto-reconnecting',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.blue.withAlpha(200),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _StatusFooter extends StatelessWidget {
  const _StatusFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryBg,
      padding: const EdgeInsets.fromLTRB(AppTheme.pad, 8, AppTheme.pad, 12),
      child: const Text(
        'InfraGuard MVP  •  Zero Trust Middleware Security Proxy',
        style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
        textAlign: TextAlign.center,
      ),
    );
  }
}
