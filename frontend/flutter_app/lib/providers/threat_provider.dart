import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

/// Describes the live connection state shown in the UI status bar.
enum ConnectionStatus {
  loading,   // First fetch not yet complete
  connected, // WebSocket connected
  offline,   // WebSocket disconnected
}

/// Provides application state and resolves incidents.
/// Listens to the backend via WebSockets.
class ThreatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  AppStateModel? _appState;
  bool _isResolving = false;
  ConnectionStatus _connectionStatus = ConnectionStatus.loading;

  /// Timestamp of the last successful API response — used in the offline screen.
  DateTime? _lastHeartbeat;

  StreamSubscription? _stateSubscription;
  StreamSubscription? _connectionSubscription;

  AppStateModel? get appState => _appState;
  bool get isLoading => _connectionStatus == ConnectionStatus.loading;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  bool get isResolving => _isResolving;
  ConnectionStatus get connectionStatus => _connectionStatus;
  DateTime? get lastHeartbeat => _lastHeartbeat;
  int get payloadsScanned => _appState?.totalPayloads ?? 0;

  ThreatProvider() {
    _startListening();
  }

  void _startListening() {
    _apiService.connectWebSocket();

    _connectionSubscription = _apiService.connectionStream.listen((isConnected) {
      if (isConnected) {
        _connectionStatus = ConnectionStatus.connected;
      } else {
        _connectionStatus = ConnectionStatus.offline;
        developer.log('[ThreatProvider] WebSocket unreachable — status offline', name: 'InfraGuard');
      }
      notifyListeners();
    });

    _stateSubscription = _apiService.stateStream.listen((state) {
      _appState = state;
      _connectionStatus = ConnectionStatus.connected;
      _lastHeartbeat = DateTime.now();
      
      // Check and trigger notifications if state changed
      NotificationService().checkAndNotify(this);
      
      notifyListeners();
    });
  }

  /// Reconnects the API service. Use this when settings change.
  void reconnect() {
    _apiService.disconnect();
    _connectionStatus = ConnectionStatus.loading;
    notifyListeners();
    
    // Slight delay to ensure clean disconnect before reconnecting
    Future.delayed(const Duration(milliseconds: 500), () {
      _apiService.connectWebSocket();
    });
  }

  /// Sends an admin resolution action.
  /// Returns true on success. The caller is responsible for showing UI feedback.
  Future<bool> resolve(String incidentId, String action) async {
    if (_isResolving) return false;
    _isResolving = true;
    notifyListeners();

    final success = await _apiService.resolveIncident(incidentId, action);
    _isResolving = false;
    notifyListeners();
    return success;
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
