import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/threat_provider.dart';

class ThreatMonitorScreen extends StatelessWidget {
  const ThreatMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              'InfraGuard Admin',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            Text(
              'Zero-Trust AI Runtime Protection',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Consumer<ThreatProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(
                      provider.isConnected ? Icons.cloud_done : Icons.cloud_off,
                      color: provider.isConnected ? Colors.greenAccent : Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      provider.isConnected ? 'Connected' : 'Offline',
                      style: TextStyle(
                        color: provider.isConnected ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ThreatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text('Establishing Secure Connection...'),
                ],
              ),
            );
          }

          if (!provider.isConnected) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
                  SizedBox(height: 16),
                  Text(
                    'Proxy Offline',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Unable to connect to the backend proxy.', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 24),
                  Text('Auto-retrying connection...', style: TextStyle(color: Colors.blueAccent)),
                ],
              ),
            );
          }

          final state = provider.appState!;
          if (state.systemStatus == 'SECURE' || state.activeThreats.isEmpty) {
            return _buildSecureState();
          }

          return _buildThreatState(context, provider);
        },
      ),
      bottomNavigationBar: const BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'InfraGuard MVP • Zero-Trust Middleware Security Proxy',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildSecureState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.greenAccent.withAlpha(25),
              border: Border.all(color: Colors.greenAccent.withAlpha(76), width: 2),
            ),
            child: const Icon(Icons.security, color: Colors.greenAccent, size: 120),
          ),
          const SizedBox(height: 32),
          const Text(
            'SYSTEM SECURE',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: Colors.greenAccent),
          ),
          const SizedBox(height: 12),
          const Text(
            'All active agents are operating within nominal parameters.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatState(BuildContext context, ThreatProvider provider) {
    final incident = provider.appState!.activeThreats.first;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 80),
              const SizedBox(height: 16),
              const Text(
                'THREAT DETECTED',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 2.0),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                      ),
                      child: const Text(
                        'HIGH SEVERITY ALERT',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow(Icons.fingerprint, 'Incident ID', incident.incidentId),
                          _infoRow(Icons.smart_toy, 'Agent', incident.agentId),
                          _infoRow(Icons.rule, 'Matched Rule', incident.matchedRule),
                          _infoRow(Icons.description, 'Reason', incident.reason),
                          _infoRow(Icons.access_time, 'Timestamp', incident.timestamp),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _buildActionButtons(context, provider, incident.incidentId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThreatProvider provider, String incidentId) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text('ALLOW (SAFE)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () => _handleAction(context, provider, incidentId, 'ALLOW'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.block, color: Colors.white),
            label: const Text('BLOCK COMMAND', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () => _handleAction(context, provider, incidentId, 'BLOCK'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.gavel, color: Colors.white),
            label: const Text('QUARANTINE AGENT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () => _confirmQuarantine(context, provider, incidentId),
          ),
        ),
      ],
    );
  }

  void _handleAction(BuildContext context, ThreatProvider provider, String incidentId, String action) async {
    final success = await provider.resolve(incidentId, action);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Action $action applied successfully.' : 'Failed to apply action.'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmQuarantine(BuildContext context, ThreatProvider provider, String incidentId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Confirm Quarantine'),
            ],
          ),
          content: const Text(
            'Are you sure you want to quarantine this agent? This will forcefully terminate the subprocess and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleAction(context, provider, incidentId, 'QUARANTINE');
              },
              child: const Text('QUARANTINE', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
