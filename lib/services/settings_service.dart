import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_settings_model.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  
  // ✅ Estados esperados pela tela de configurações
  bool _autoSpeak = true;
  double _voiceSpeed = 0.5;

  ProfileSettings _settings = ProfileSettings(
    voiceRate: 0.5,
    voicePitch: 1.0,
    highContrast: false,
    selectedVoice: 'pt-BR',
  );

  // Getters
  bool get autoSpeak => _autoSpeak;
  double get voiceSpeed => _voiceSpeed;
  ProfileSettings get settings => _settings;
  bool _isSttAvailable = false;
  bool get isSttAvailable => _isSttAvailable;

  Future<void> init() async {
    await _loadSettings();
    await _initTts();
    await initSpeech();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage(_settings.selectedVoice);
      await _flutterTts.setSpeechRate(_voiceSpeed);
      await _flutterTts.setPitch(_settings.voicePitch);
      
      _flutterTts.setErrorHandler((msg) {
        debugPrint("TTS Error: $msg. Reinicializando...");
        _initTts();
      });
    } catch (e) {
      debugPrint("Erro ao inicializar TTS: $e");
    }
  }

  Future<void> initSpeech() async {
    try {
      _isSttAvailable = await _speechToText.initialize();
      notifyListeners();
    } catch (e) {
      _isSttAvailable = false;
    }
  }

  // ✅ Métodos esperados pela tela
  void setAutoSpeak(bool value) {
    _autoSpeak = value;
    _saveSettings();
    notifyListeners();
  }

  void setVoiceSpeed(double value) {
    _voiceSpeed = value;
    _flutterTts.setSpeechRate(value);
    _saveSettings();
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (text.isEmpty || !_autoSpeak) return;
    try {
      var result = await _flutterTts.speak(text);
      if (result == 0) {
        await _initTts();
        await _flutterTts.speak(text);
      }
    } catch (e) {
      debugPrint("Erro ao falar: $e");
    }
  }

  Future<void> updateSettings(ProfileSettings newSettings) async {
    _settings = newSettings;
    _voiceSpeed = newSettings.voiceRate;
    await _initTts();
    await _saveSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSpeak = prefs.getBool('autoSpeak') ?? true;
    _voiceSpeed = prefs.getDouble('voiceRate') ?? 0.5;
    
    final pitch = prefs.getDouble('voicePitch') ?? 1.0;
    final contrast = prefs.getBool('highContrast') ?? false;
    final voice = prefs.getString('selectedVoice') ?? 'pt-BR';
    
    _settings = ProfileSettings(
      voiceRate: _voiceSpeed, 
      voicePitch: pitch, 
      highContrast: contrast, 
      selectedVoice: voice
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSpeak', _autoSpeak);
    await prefs.setDouble('voiceRate', _voiceSpeed);
    await prefs.setDouble('voicePitch', _settings.voicePitch);
    await prefs.setBool('highContrast', _settings.highContrast);
    await prefs.setString('selectedVoice', _settings.selectedVoice);
  }

  SpeechToText get speechToText => _speechToText;
  Future<void> stop() async => await _flutterTts.stop();
}