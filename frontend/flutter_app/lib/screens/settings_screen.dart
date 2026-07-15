import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/threat_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: SettingsService.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) {
      AppTheme.showSnack(context, message: 'URL cannot be empty', success: false);
      return;
    }

    await SettingsService.setBaseUrl(newUrl);
    
    if (mounted) {
      // Reconnect the provider using the new settings
      context.read<ThreatProvider>().reconnect();
      AppTheme.showSnack(context, message: 'Settings saved', success: true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        title: const Text(
          'Environment Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend API Base URL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: AppTheme.primaryText),
              decoration: InputDecoration(
                hintText: 'e.g. http://192.168.1.10:8000',
                hintStyle: const TextStyle(color: AppTheme.mutedText),
                filled: true,
                fillColor: AppTheme.secondaryBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Presets',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetButton('Local (USB)', 'http://127.0.0.1:8000'),
                _buildPresetButton('LAN (Wi-Fi)', 'http://192.168.x.x:8000'),
                _buildPresetButton('ngrok', 'https://flying-resemble-canopener.ngrok-free.dev'),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save & Reconnect',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, String urlTemplate) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppTheme.secondaryBg,
      labelStyle: const TextStyle(color: AppTheme.primaryText, fontSize: 13),
      onPressed: () {
        _urlController.text = urlTemplate;
      },
    );
  }
}
