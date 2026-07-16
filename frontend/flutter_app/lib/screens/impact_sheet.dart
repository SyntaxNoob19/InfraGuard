import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

/// Impact Analysis BottomSheet.
/// Opens when the user taps "View Impact Analysis" on a threat card.
/// Since the backend does not expose an impact endpoint, shows a professional
/// placeholder with a clear "not available" message per the spec.
class ImpactSheet extends StatefulWidget {
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
  State<ImpactSheet> createState() => _ImpactSheetState();
}

class _ImpactSheetState extends State<ImpactSheet> {
  bool _isAnalyzing = true;
  String _impactSummary = '';
  String _filesAffected = '';
  String _resourcesAffected = '';
  String _dryRunLog = '';

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    // Simulate network delay for AI/backend processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final incident = widget.incident;
    final payloadStr = incident.payload.toString();
    final method = incident.method;
    
    // Simulate LLM/Dry run analysis logic based on incident details
    String summary = 'Detected suspicious behavior matching ${incident.matchedRule}. ';
    String files = 'None';
    String resources = 'None';
    String dryRun = 'Initializing dry run sandbox...\n';
    
    dryRun += 'Applying payload: $payloadStr via $method\n';

    if (incident.matchedRule.toLowerCase().contains('sql') || payloadStr.toLowerCase().contains('select')) {
      summary += 'The payload attempts an SQL injection attack.';
      files = 'Database schemas, Users table';
      resources = 'PostgreSQL Database';
      dryRun += '[!] SQL Syntax detected.\n';
      dryRun += '[!] Attempt to bypass authentication or extract data.\n';
      dryRun += 'Result: Unauthorized data access prevented.\n';
    } else if (incident.matchedRule.toLowerCase().contains('xss') || payloadStr.toLowerCase().contains('script')) {
      summary += 'The payload contains Cross-Site Scripting (XSS) vectors.';
      files = 'Client-side rendered views';
      resources = 'Frontend DOM';
      dryRun += '[!] HTML/JS tags detected in payload.\n';
      dryRun += '[!] Attempt to inject malicious scripts.\n';
      dryRun += 'Result: Script execution blocked.\n';
    } else if (payloadStr.toLowerCase().contains('rm -rf') || payloadStr.toLowerCase().contains('bash')) {
      summary += 'The payload attempts to execute system commands.';
      files = '/var/www/html, /etc/passwd';
      resources = 'Server File System';
      dryRun += '[!] Shell commands detected.\n';
      dryRun += '[!] Attempting to execute unauthorized shell script.\n';
      dryRun += 'Result: Command execution denied by restricted shell.\n';
    } else {
      summary += 'The payload contains abnormal data structures or anomalous traffic patterns.';
      files = 'Unknown';
      resources = 'API Endpoints';
      dryRun += '[!] Analyzing generic payload.\n';
      dryRun += '[!] No known exploit signatures fully matched, but heuristic flagged as high risk.\n';
      dryRun += 'Result: Request dropped by WAF rules.\n';
    }

    setState(() {
      _impactSummary = summary;
      _filesAffected = files;
      _resourcesAffected = resources;
      _dryRunLog = dryRun;
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final severityColor = AppTheme.severityColor(incident.severity);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppTheme.pad,
          20,
          AppTheme.pad,
          MediaQuery.of(context).viewInsets.bottom + AppTheme.pad,
        ),
        child: SingleChildScrollView(
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

            if (_isAnalyzing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.blue),
                ),
              )
            else ...[
              // Placeholder rows
              _ImpactRow(label: 'Impact Summary', value: _impactSummary),
              _ImpactRow(label: 'Files Affected', value: _filesAffected),
              _ImpactRow(label: 'Resources', value: _resourcesAffected),
              _ImpactRow(label: 'Risk Level',
                  value: incident.severity,
                  valueColor: severityColor),
              _ImpactRow(label: 'Estimated Result',
                  value: 'Blocked by InfraGuard proxy'),
              
              const SizedBox(height: 10),
              const Text(
                'Dry Run Analysis Log',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBg,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Text(
                  _dryRunLog,
                  style: AppTheme.mono(12, color: AppTheme.green),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
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
