import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/threat_provider.dart';
import 'screens/splash_screen.dart';

import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.init();
  await NotificationService().init();

  runApp(const InfraGuardApp());
}

class InfraGuardApp extends StatelessWidget {
  const InfraGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThreatProvider()),
      ],
      child: MaterialApp(
        title: 'InfraGuard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SplashScreen(),
      ),
    );
  }
}
