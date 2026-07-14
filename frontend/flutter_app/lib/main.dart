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
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF38BDF8), // Light Blue
            secondary: Color(0xFF818CF8), // Indigo
            surface: Color(0xFF1E293B), // Slate 800
            error: Color(0xFFEF4444), // Red 500
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F172A),
            elevation: 0,
            centerTitle: true,
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFF1E293B),
            elevation: 8,
          ),
        ),
        home: const ThreatMonitorScreen(),
      ),
    );
  }
}
