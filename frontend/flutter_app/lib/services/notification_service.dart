import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/connection_status.dart';
import '../providers/threat_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  ConnectionStatus? _lastConnectionStatus;
  bool _wasSecure = true;

  Future<void> init({bool requestPermission = true}) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    if (requestPermission) {
      // Request permissions for Android 13+
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  void checkAndNotify(ThreatProvider provider) {
    // Determine connection state transition
    if (_lastConnectionStatus != provider.connectionStatus) {
      if (provider.connectionStatus == ConnectionStatus.offline &&
          _lastConnectionStatus != null) {
        showWarning(
          'Connection Lost',
          'Waiting for backend...',
        );
      }
      _lastConnectionStatus = provider.connectionStatus;
    }

    // Determine threat state transition
    final isSecure = provider.appState == null ||
        provider.appState!.activeThreats.isEmpty;

    if (!isSecure && _wasSecure && provider.appState != null) {
      final incident = provider.appState!.activeThreats.first;
      showCriticalAlert(
        'Threat Detected',
        '${incident.agentId} attempted ${incident.method}\nSeverity ${incident.severity}',
      );
    } else if (isSecure && !_wasSecure && provider.isConnected) {
      showInfo(
        'System Secure',
        'Runtime monitoring resumed.',
      );
    }

    _wasSecure = isSecure;
  }

  Future<void> showCriticalAlert(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'critical_alerts',
      'Critical Alerts',
      channelDescription: 'High priority alerts for detected threats',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id: 0, title: title, body: body, notificationDetails: details);
  }

  Future<void> showWarning(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'warnings',
      'Warnings',
      channelDescription: 'Connection and system warnings',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id: 1, title: title, body: body, notificationDetails: details);
  }

  Future<void> showInfo(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'info',
      'Information',
      channelDescription: 'General system status updates',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id: 2, title: title, body: body, notificationDetails: details);
  }
}
