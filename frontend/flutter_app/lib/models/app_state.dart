class Incident {
  final String incidentId;
  final String agentId;
  final String method;
  final String severity;
  final String matchedRule;
  final String reason;
  final String status;
  final String timestamp;
  final Map<String, dynamic> payload;

  Incident({
    required this.incidentId,
    required this.agentId,
    required this.method,
    required this.severity,
    required this.matchedRule,
    required this.reason,
    required this.status,
    required this.timestamp,
    required this.payload,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      incidentId: json['incident_id'] ?? '',
      agentId: json['agent_id'] ?? '',
      method: json['method'] ?? '',
      severity: json['severity'] ?? '',
      matchedRule: json['matched_rule'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? '',
      timestamp: json['timestamp'] ?? '',
      payload: json['payload'] ?? {},
    );
  }
}

class AppStateModel {
  final String systemStatus;
  final int activeAgents;
  final List<Incident> activeThreats;

  AppStateModel({
    required this.systemStatus,
    required this.activeAgents,
    required this.activeThreats,
  });

  factory AppStateModel.fromJson(Map<String, dynamic> json) {
    var threatsFromJson = json['active_threats'] as List? ?? [];
    List<Incident> threatsList = threatsFromJson.map((i) => Incident.fromJson(i)).toList();

    return AppStateModel(
      systemStatus: json['system_status'] ?? 'SECURE',
      activeAgents: json['active_agents'] ?? 0,
      activeThreats: threatsList,
    );
  }
}
