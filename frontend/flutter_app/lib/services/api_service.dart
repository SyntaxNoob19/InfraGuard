import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/app_state.dart';
import 'settings_service.dart';

/// REST and WebSocket client for the InfraGuard FastAPI backend.
class ApiService {
  static String get httpBaseUrl => SettingsService.baseUrl;
  static String get wsBaseUrl {
    final url = SettingsService.baseUrl;
    if (url.startsWith('https://')) {
      return url.replaceFirst('https://', 'wss://');
    } else if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'ws://');
    }
    return url;
  }
  static const String apiKey = 'YOUR_API_KEY_HERE';

  /// Common headers — includes the ngrok browser-warning bypass header
  /// so the app does not receive the ngrok interstitial HTML page.
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'ngrok-skip-browser-warning': 'true',
      };

  static const Duration _timeout = Duration(seconds: 8);

  WebSocketChannel? _channel;
  final _stateController = StreamController<AppStateModel>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  Stream<AppStateModel> get stateStream => _stateController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  void connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$wsBaseUrl/api/ws'));
      _connectionController.add(true);
      
      _channel!.stream.listen(
        (message) {
          try {
            final decoded = json.decode(message) as Map<String, dynamic>;
            if (decoded['event'] == 'state_update') {
              _stateController.add(AppStateModel.fromJson(decoded));
            }
          } catch (e) {
            developer.log('WS Decode Error: $e');
          }
        },
        onDone: () => _handleDisconnect(),
        onError: (error) => _handleDisconnect(),
      );

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_channel != null) {
          _channel!.sink.add('ping: Flutter-Admin');
        }
      });
      
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _connectionController.add(false);
    _channel = null;
    _pingTimer?.cancel();
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), connectWebSocket);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connectionController.add(false);
  }

  Future<AppStateModel?> fetchStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$httpBaseUrl/api/status'), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return AppStateModel.fromJson(decoded);
      }

      developer.log(
        '[ApiService] fetchStatus failed: HTTP ${response.statusCode}',
        name: 'InfraGuard',
      );
      return null;
    } on Exception catch (e) {
      developer.log(
        '[ApiService] fetchStatus error: $e',
        name: 'InfraGuard',
      );
      return null;
    }
  }

  Future<bool> resolveIncident(String incidentId, String action) async {
    try {
      final response = await http
          .post(
            Uri.parse('$httpBaseUrl/api/resolve'),
            headers: _headers,
            body: json.encode({'incident_id': incidentId, 'action': action}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) return true;

      developer.log(
        '[ApiService] resolveIncident failed: HTTP ${response.statusCode} — ${response.body}',
        name: 'InfraGuard',
      );
      return false;
    } on Exception catch (e) {
      developer.log(
        '[ApiService] resolveIncident error: $e',
        name: 'InfraGuard',
      );
      return false;
    }
  }
}
