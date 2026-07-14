import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/threat_provider.dart';

class ThreatMonitorScreen extends StatelessWidget {
  const ThreatMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InfraGuard Admin'),
        centerTitle: true,
      ),
      body: Consumer<ThreatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final state = provider.appState;
          if (state == null) {
            return const Center(child: Text('Failed to connect to proxy.'));
          }

          if (state.systemStatus == 'SECURE' || state.activeThreats.isEmpty) {
            return _buildSecureState();
          }

          return _buildThreatState(context, provider);
        },
      ),
    );
  }

  Widget _buildSecureState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.shield, color: Colors.green, size: 100),
          SizedBox(height: 20),
          Text(
            'System Secure',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text('Connected and Monitoring', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildThreatState(BuildContext context, ThreatProvider provider) {
    final incident = provider.appState!.activeThreats.first;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 80),
          const SizedBox(height: 16),
          const Text(
            'THREAT DETECTED',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Incident ID', incident.incidentId),
                  _infoRow('Agent', incident.agentId),
                  _infoRow('Severity', incident.severity),
                  _infoRow('Matched Rule', incident.matchedRule),
                  _infoRow('Reason', incident.reason),
                  _infoRow('Timestamp', incident.timestamp),
                ],
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => provider.resolve(incident.incidentId, 'ALLOW'),
            child: const Text('ALLOW (SAFE)', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => provider.resolve(incident.incidentId, 'BLOCK'),
            child: const Text('BLOCK COMMAND', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => provider.resolve(incident.incidentId, 'QUARANTINE'),
            child: const Text('QUARANTINE AGENT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
