import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';

class ThreatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  AppStateModel? _appState;
  Timer? _timer;
  bool _isLoading = true;

  AppStateModel? get appState => _appState;
  bool get isLoading => _isLoading;

  bool get isConnected => _appState != null && !_isLoading;

  ThreatProvider() {
    _startPolling();
  }

  void _startPolling() {
    _fetchStatus(); // initial fetch
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchStatus();
    });
  }

  Future<void> _fetchStatus() async {
    final state = await _apiService.fetchStatus();
    if (state != null) {
      _appState = state;
      _isLoading = false;
      notifyListeners();
    } else {
      // If the API fails completely, keep the old state but maybe we should clear it if we want it to show offline?
      // Since it says to add offline state, if fetch fails, we should handle offline.
      _appState = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resolve(String incidentId, String action) async {
    final success = await _apiService.resolveIncident(incidentId, action);
    if (success) {
      await _fetchStatus(); // force immediate refresh
    }
    return success;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
