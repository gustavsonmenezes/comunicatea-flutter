import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _settings.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: SwitchListTile(
              title: const Text('Síntese de voz'),
              subtitle: const Text('Ativar fala automática'),
              value: _settings.autoSpeak,
              onChanged: (val) {
                _settings.setAutoSpeak(val);
                setState(() {});
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Velocidade da voz'),
                  subtitle: Slider(
                    value: _settings.voiceSpeed,
                    min: 0.3,
                    max: 1.0,
                    divisions: 7,
                    onChanged: (val) {
                      _settings.setVoiceSpeed(val);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}