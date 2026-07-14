import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/threat_provider.dart';
import 'screens/threat_monitor.dart';

void main() {
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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        ),
        home: const ThreatMonitorScreen(),
      ),
    );
  }
}
