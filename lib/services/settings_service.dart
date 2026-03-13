// lib/services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _autoSpeakKey = 'auto_speak';
  static const String _voiceSpeedKey = 'voice_speed';
  static const String _highContrastKey = 'high_contrast';
  static const String _pictogramSizeKey = 'pictogram_size';

  bool _autoSpeak = true;
  double _voiceSpeed = 0.5;
  bool _highContrast = false;
  double _pictogramSize = 100.0;

  bool get autoSpeak => _autoSpeak;
  double get voiceSpeed => _voiceSpeed;
  bool get highContrast => _highContrast;
  double get pictogramSize => _pictogramSize;

  Future<void> init() async {
    await _loadSettings();
  }

  Future<void> setAutoSpeak(bool value) async {
    _autoSpeak = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSpeakKey, value);
  }

  Future<void> setVoiceSpeed(double value) async {
    _voiceSpeed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_voiceSpeedKey, value);
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
  }

  Future<void> setPictogramSize(double value) async {
    _pictogramSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pictogramSizeKey, value);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSpeak = prefs.getBool(_autoSpeakKey) ?? true;
    _voiceSpeed = prefs.getDouble(_voiceSpeedKey) ?? 0.5;
    _highContrast = prefs.getBool(_highContrastKey) ?? false;
    _pictogramSize = prefs.getDouble(_pictogramSizeKey) ?? 100.0;
  }
}
