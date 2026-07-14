import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// InfraGuard enterprise design system.
/// Aesthetic reference: Microsoft Defender, CrowdStrike Falcon, SentinelOne.
abstract final class AppTheme {
  // ── Colour palette ────────────────────────────────────────────────────────
  static const Color primaryBg    = Color(0xFF081426);
  static const Color secondaryBg  = Color(0xFF0E1B2F);
  static const Color surfaceCard  = Color(0xFF152238);
  static const Color elevatedCard = Color(0xFF1C2C44);
  static const Color divider      = Color(0xFF2B3D58);

  static const Color primaryText   = Color(0xFFF5F7FA);
  static const Color secondaryText = Color(0xFFA6B1C2);
  static const Color mutedText     = Color(0xFF73839B);

  static const Color green = Color(0xFF00C853);
  static const Color amber = Color(0xFFFFB300);
  static const Color red   = Color(0xFFF44336);
  static const Color blue  = Color(0xFF2196F3);

  // ── Spacing / Radii ────────────────────────────────────────────────────────
  static const double pad          = 24.0;
  static const double cardPad      = 20.0;
  static const double radius       = 16.0;
  static const double btnRadius    = 14.0;
  static const double dialogRadius = 18.0;
  static const double chipRadius   = 24.0;

  // ── Monospace (logs, payloads, IDs only) ───────────────────────────────────
  static TextStyle mono(double size,
      {Color color = primaryText, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.robotoMono(fontSize: size, color: color, fontWeight: weight);

  // ── Severity ───────────────────────────────────────────────────────────────
  static Color severityColor(String s) => switch (s.toUpperCase()) {
        'HIGH'   => red,
        'MEDIUM' => amber,
        _        => green,
      };

  // ── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get theme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: primaryBg,
      colorScheme: const ColorScheme.dark(
        primary: blue,
        secondary: green,
        surface: surfaceCard,
        error: red,
        onSurface: primaryText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBg,
        elevation: 0,
        centerTitle: false,
        titleSpacing: pad,
        iconTheme: IconThemeData(color: primaryText),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
      dividerColor: divider,
      textTheme: base.textTheme.copyWith(
        displayLarge:  const TextStyle(fontSize: 32, fontWeight: FontWeight.bold,    color: primaryText),
        headlineMedium:const TextStyle(fontSize: 26, fontWeight: FontWeight.w600,    color: primaryText),
        titleLarge:    const TextStyle(fontSize: 20, fontWeight: FontWeight.w500,    color: primaryText),
        bodyLarge:     const TextStyle(fontSize: 16, fontWeight: FontWeight.normal,  color: primaryText),
        bodyMedium:    const TextStyle(fontSize: 14, fontWeight: FontWeight.normal,  color: secondaryText),
        labelSmall:    const TextStyle(fontSize: 13, fontWeight: FontWeight.normal,  color: mutedText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(btnRadius)),
          elevation: 0,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: elevatedCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dialogRadius)),
      ),
    );
  }

  // ── Enterprise snackbar ────────────────────────────────────────────────────
  static void showSnack(
    BuildContext context, {
    required String message,
    required bool success,
  }) {
    final accent = success ? green : red;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: elevatedCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(btnRadius),
          side: BorderSide(color: accent, width: 1),
        ),
        content: Row(
          children: [
            Icon(success ? Icons.check_circle_outline : Icons.error_outline,
                color: accent, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: primaryText, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
