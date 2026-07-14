import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'notification_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'foreground_service', // id
    'Agent Running', // title
    description: 'Maintains background connection to the InfraGuard backend.',
    importance: Importance.low, // must be low to avoid constant buzzing
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'foreground_service',
      initialNotificationTitle: 'InfraGuard Agent',
      initialNotificationContent: 'Monitoring environment in background',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // Initialize notifications inside this isolate without requesting permissions
  await NotificationService().init(requestPermission: false);

  final apiService = ApiService();
  bool wasSecure = true;

  // Poll the API every 3 seconds while in the background
  Timer.periodic(const Duration(seconds: 3), (timer) async {
    try {
      final state = await apiService.fetchStatus();
      
      if (state != null) {
        final isSecure = state.activeThreats.isEmpty;

        if (!isSecure && wasSecure) {
          final incident = state.activeThreats.first;
          await NotificationService().showCriticalAlert(
            'Threat Detected (Background)',
            '${incident.agentId} attempted ${incident.method}\nSeverity ${incident.severity}',
          );
        } else if (isSecure && !wasSecure) {
          await NotificationService().showInfo(
            'System Secure',
            'Threat resolved. Resuming background monitoring.',
          );
        }
        wasSecure = isSecure;
      }
    } catch (e) {
      // Ignore network errors in the background to avoid spamming the user
    }
  });
}
