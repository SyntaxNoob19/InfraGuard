import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Collapsed-by-default expandable JSON payload viewer.
/// Uses ExpansionTile so the payload never dominates the screen.
class PayloadViewer extends StatelessWidget {
  final Map<String, dynamic> payload;

  const PayloadViewer({super.key, required this.payload});

  String get _pretty {
    try {
      return const JsonEncoder.withIndent('  ').convert(payload);
    } catch (_) {
      return payload.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.secondaryBg,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.divider, width: 1),
        ),
        child: Theme(
          // Remove ExpansionTile's default divider
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: EdgeInsets.zero,
            leading: const Icon(Icons.data_object_rounded,
                color: AppTheme.blue, size: 18),
            title: const Text(
              'View Intercepted Payload',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.secondaryText,
              ),
            ),
            iconColor: AppTheme.mutedText,
            collapsedIconColor: AppTheme.mutedText,
            children: [
              const Divider(height: 1, color: AppTheme.divider),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    _pretty,
                    style: AppTheme.mono(12, color: const Color(0xFF89DDFF)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
