/// Data models for the InfraGuard Flutter app.
/// Mirrors the backend proxy models (backend/proxy/models.py).
library;

class LogEntryModel {
  final String type;
  final String message;
  final String timestamp;

  const LogEntryModel({
    required this.type,
    required this.message,
    required this.timestamp,
  });

  factory LogEntryModel.fromJson(Map<String, dynamic> json) {
    return LogEntryModel(
      type: json['type'] as String? ?? 'INFO',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}

class IncidentModel {
  final String incidentId;
  final String agentId;
  final String method;
  final String severity;
  final String matchedRule;
  final String reason;
  final String status;
  final String timestamp;
  final Map<String, dynamic> payload;
  final String? resolvedAction;
  final String? resolutionTimestamp;

  const IncidentModel({
    required this.incidentId,
    required this.agentId,
    required this.method,
    required this.severity,
    required this.matchedRule,
    required this.reason,
    required this.status,
    required this.timestamp,
    required this.payload,
    this.resolvedAction,
    this.resolutionTimestamp,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      incidentId: json['incident_id'] as String? ?? '',
      agentId: json['agent_id'] as String? ?? '',
      method: json['method'] as String? ?? '',
      // Backend returns severity as {"LOW":"LOW"} enum — the value is the string name.
      severity: _enumValue(json['severity']) ?? 'HIGH',
      matchedRule: json['matched_rule'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: _enumValue(json['status']) ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      resolvedAction: json['resolved_action'] as String?,
      resolutionTimestamp: json['resolution_timestamp'] as String?,
    );
  }

  /// FastAPI serialises Python Enum as {"EnumName": "EnumValue"}.
  /// This helper extracts the string value from either format.
  static String? _enumValue(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is Map) {
      // e.g. {"HIGH": "HIGH"}
      return raw.values.isNotEmpty ? raw.values.first as String? : null;
    }
    return raw.toString();
  }
}

class AppStateModel {
  final String systemStatus;
  final int activeAgents;
  final List<IncidentModel> activeThreats;
  final List<IncidentModel> resolvedThreats;
  final List<LogEntryModel> recentLogs;
  final int totalPayloads;
  final int connectedClients;

  const AppStateModel({
    required this.systemStatus,
    required this.activeAgents,
    required this.activeThreats,
    required this.resolvedThreats,
    required this.recentLogs,
    required this.totalPayloads,
    required this.connectedClients,
  });

  factory AppStateModel.fromJson(Map<String, dynamic> json) {
    List<IncidentModel> parseIncidents(dynamic raw) {
      if (raw == null) return [];
      return (raw as List).map((i) => IncidentModel.fromJson(i as Map<String, dynamic>)).toList();
    }

    List<LogEntryModel> parseLogs(dynamic raw) {
      if (raw == null) return [];
      return (raw as List).map((l) => LogEntryModel.fromJson(l as Map<String, dynamic>)).toList();
    }

    // system_status comes as an enum dict from Python e.g. {"SECURE": "SECURE"}
    final rawStatus = json['system_status'];
    final systemStatus = IncidentModel._enumValue(rawStatus) ?? 'SECURE';

    return AppStateModel(
      systemStatus: systemStatus,
      activeAgents: (json['active_agents'] as num?)?.toInt() ?? 0,
      activeThreats: parseIncidents(json['active_threats']),
      resolvedThreats: parseIncidents(json['resolved_threats']),
      recentLogs: parseLogs(json['recent_logs']),
      totalPayloads: (json['total_payloads'] as num?)?.toInt() ?? 0,
      connectedClients: (json['connected_clients'] as num?)?.toInt() ?? 0,
    );
  }
}
