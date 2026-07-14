import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

/// Describes the live connection state shown in the UI status bar.
enum ConnectionStatus {
  loading,   // First fetch not yet complete
  connected, // Last fetch succeeded
  polling,   // Connected but mid-fetch cycle
  offline,   // Last fetch failed / no response
}

/// Provides application state and resolves incidents.
/// Polls the backend every 2 seconds and exposes [connectionStatus].
class ThreatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  AppStateModel? _appState;
  Timer? _timer;
  bool _isFetching = false;
  bool _isResolving = false;
  ConnectionStatus _connectionStatus = ConnectionStatus.loading;

  /// Timestamp of the last successful API response — used in the offline screen.
  DateTime? _lastHeartbeat;

  /// Running count of payloads scanned — derived from unique "Payload Parsed"
  /// log entries seen across all polls, never decremented.
  final Set<String> _seenPayloadLogTimestamps = {};
  int _payloadsScanned = 0;

  AppStateModel? get appState => _appState;
  bool get isLoading => _connectionStatus == ConnectionStatus.loading;
  bool get isConnected =>
      _connectionStatus == ConnectionStatus.connected ||
      _connectionStatus == ConnectionStatus.polling;
  bool get isResolving => _isResolving;
  ConnectionStatus get connectionStatus => _connectionStatus;
  DateTime? get lastHeartbeat => _lastHeartbeat;
  int get payloadsScanned => _payloadsScanned;

  ThreatProvider() {
    _startPolling();
  }

  void _startPolling() {
    _fetchStatus();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchStatus());
  }

  Future<void> _fetchStatus() async {
    if (_isFetching) return;
    _isFetching = true;

    if (_connectionStatus == ConnectionStatus.connected) {
      _connectionStatus = ConnectionStatus.polling;
      notifyListeners();
    }

    final state = await _apiService.fetchStatus();
    _isFetching = false;

    if (state != null) {
      _appState = state;
      _connectionStatus = ConnectionStatus.connected;
      _lastHeartbeat = DateTime.now();
      _updatePayloadsScanned(state);
    } else {
      _appState = null;
      _connectionStatus = ConnectionStatus.offline;
      developer.log('[ThreatProvider] Backend unreachable — status offline', name: 'InfraGuard');
    }
    
    // Check and trigger notifications if state changed
    NotificationService().checkAndNotify(this);
    
    notifyListeners();
  }

  /// Counts unique "Payload Parsed" log entries to derive total payloads scanned.
  /// Using timestamps as a deduplication key (good enough for MVP polling frequency).
  void _updatePayloadsScanned(AppStateModel state) {
    for (final log in state.recentLogs) {
      if (log.message.contains('Payload Parsed') && log.timestamp.isNotEmpty) {
        if (_seenPayloadLogTimestamps.add(log.timestamp)) {
          _payloadsScanned++;
        }
      }
    }
    // Also count from resolved threats — each resolved threat = 1 payload
    for (final t in state.resolvedThreats) {
      if (t.timestamp.isNotEmpty) {
        _seenPayloadLogTimestamps.add('resolved_${t.incidentId}');
      }
    }
  }

  /// Sends an admin resolution action.
  /// Returns true on success. The caller is responsible for showing UI feedback.
  Future<bool> resolve(String incidentId, String action) async {
    if (_isResolving) return false;
    _isResolving = true;
    notifyListeners();

    final success = await _apiService.resolveIncident(incidentId, action);
    _isResolving = false;

    if (success) {
      await _fetchStatus();
    } else {
      notifyListeners();
    }
    return success;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
