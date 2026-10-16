import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pictogram_model.dart';
import '../services/speech_recognition_service.dart';
import '../services/sound_manager.dart';
import '../services/gamification_service.dart';
import '../services/speech_log_service.dart';
import '../models/speech_log_model.dart';

class VoiceConfirmationDialog extends StatefulWidget {
  final Pictogram pictogram;
  const VoiceConfirmationDialog({Key? key, required this.pictogram}) : super(key: key);

  @override
  _VoiceConfirmationDialogState createState() => _VoiceConfirmationDialogState();
}

class _VoiceConfirmationDialogState extends State<VoiceConfirmationDialog> with SingleTickerProviderStateMixin {
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final GamificationService _gamificationService = GamificationService();
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechLogService _logService = SpeechLogService();

  bool _isEscutandoPronuncia = true; // 🔥 Passo 1: Ouvindo a pronúncia primeiro
  bool _isSuccess = false;
  bool _isListening = false;
  bool _showNotUnderstood = false;
  double _currentConfidence = 0.0;
  String _currentRecognized = '';
  String? _childId;
  int _attempts = 0; // 🔥 Contador de tentativas

  @override
  void initState() {
    super.initState();
    _playPronunciationThenListen();
    _loadChildId();
  }

  Future<void> _loadChildId() async {
    final prefs = await SharedPreferences.getInstance();
    _childId = prefs.getString('currentChildId') ?? FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _speechService.cancelListening();
    _flutterTts.stop();
    super.dispose();
  }

  // 🔊 PASSO 1: Falar a pronúncia para a criança escutar primeiro
  Future<void> _playPronunciationThenListen() async {
    await _speechService.cancelListening();
    
    setState(() {
      _isEscutandoPronuncia = true;
      _isListening = false;
      _showNotUnderstood = false;
    });

    try {
      await _flutterTts.setLanguage("pt-BR");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(widget.pictogram.label);
    } catch (e) {
      debugPrint("Erro ao sintetizar pronúncia: $e");
    }

    // 🎙️ PASSO 2: Após a criança escutar a pronúncia (2 segundos), ativa o microfone para ela falar
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && !_isSuccess) {
        setState(() {
          _isEscutandoPronuncia = false;
        });
        _startListening();
      }
    });
  }

  void _startListening() async {
    try {
      await _flutterTts.stop();
    } catch (e) {}

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    setState(() {
      _isEscutandoPronuncia = false;
      _isListening = true;
      _currentConfidence = 0.0;
      _currentRecognized = '';
      _showNotUnderstood = false;
    });

    final bool available = await _speechService.initSpeech();
    if (!mounted) return;

    if (available) {
      final started = await _speechService.startListening(
        onResult: (words) {
          if (mounted) {
            setState(() {
              _currentRecognized = words;
              _currentConfidence = _speechService.confidence;
            });
            _checkMatch(words);
          }
        },
      );

      if (!started && mounted) {
        _handleFailure();
        return;
      }

      // Timeout de segurança após 8 segundos de escuta
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted && _isListening && !_isSuccess) {
          _handleFailure();
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _isListening = false;
          _showNotUnderstood = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reconhecimento de voz indisponível ou permissão não concedida.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  void _checkMatch(String spokenWords) {
    if (_isSuccess || spokenWords.isEmpty) return;

    final targetWord = _normalize(widget.pictogram.label);
    final recognized = _normalize(spokenWords);

    if (targetWord.isEmpty || recognized.isEmpty) return;

    bool isMatch = false;

    if (recognized == targetWord) {
      isMatch = true;
    } else if (recognized.contains(targetWord) || targetWord.contains(recognized)) {
      isMatch = true;
    } else {
      // 1. Distância de Levenshtein direta na palavra
      final distance = _levenshteinDistance(recognized, targetWord);
      final maxAllowedDistance = targetWord.length <= 4 ? 1 : 2;
      if (distance <= maxAllowedDistance) {
        isMatch = true;
      } else {
        // 2. Comparação por palavras individuais com distância fonética
        final recognizedTokens = recognized.split(RegExp(r'\s+'));
        final targetTokens = targetWord.split(RegExp(r'\s+'));

        for (var recToken in recognizedTokens) {
          for (var tarToken in targetTokens) {
            if (recToken == tarToken) {
              isMatch = true;
              break;
            }
            if (recToken.length >= 3 && tarToken.length >= 3) {
              if (_levenshteinDistance(recToken, tarToken) <= 1) {
                isMatch = true;
                break;
              }
            }
          }
          if (isMatch) break;
        }
      }
    }

    if (isMatch) {
      _handleSuccess();
    }
  }

  // 🔥 Registra falha ou tentativa não compreendida
  void _handleFailure() async {
    if (!mounted || _isSuccess) return;

    setState(() {
      _showNotUnderstood = true;
      _isListening = false;
      _attempts++;
    });

    _speechService.stopListening();
    await SoundManager().playError();

    if (_childId != null) {
      await _logService.saveLog(SpeechLog(
        childId: _childId!,
        pictogramId: widget.pictogram.id,
        targetWord: widget.pictogram.label,
        recognizedWords: _currentRecognized.isEmpty ? "(Silêncio/Ruído)" : _currentRecognized,
        isSuccess: false,
        confidence: _currentConfidence,
      ));
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showNotUnderstood = false);
    });
  }

  String _normalize(String text) {
    const accents = 'áàãâäéèêëíìîïóòõôöúùûüç';
    const noAccents = 'aaaaaeeeeiiiiooooouuuuc';
    String result = text.toLowerCase().trim();
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], noAccents[i]);
    }
    return result.replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  void _handleSuccess() async {
    setState(() { _isSuccess = true; _isListening = false; });
    await _speechService.stopListening();
    
    if (_childId != null) {
      await _logService.saveLog(SpeechLog(
        childId: _childId!,
        pictogramId: widget.pictogram.id,
        targetWord: widget.pictogram.label,
        recognizedWords: _currentRecognized,
        isSuccess: true,
        confidence: _currentConfidence,
      ));
    }
    
    await SoundManager().playSuccess();
    await _gamificationService.addStar();

    try {
      await _flutterTts.setLanguage("pt-BR");
      await _flutterTts.speak("Muito bem! ${widget.pictogram.label}!");
    } catch (e) {
      debugPrint("Erro ao sintetizar confirmação: $e");
    }

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  void _handleCancel() {
    _speechService.stopListening();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.pictogram.icon, size: 72, color: Colors.blue[800]),
            const SizedBox(height: 8),
            Text(
              widget.pictogram.label,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 20),

            // 🔊 PASSO 1: A criança ESCUTA primeiro a pronúncia da palavra
            if (_isEscutandoPronuncia)
              Column(
                children: [
                  const Icon(Icons.volume_up_rounded, size: 48, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    'Escute: "${widget.pictogram.label}"',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),

            // 🎙️ PASSO 2: Apenas APÓS escutar, libera o microfone para a criança FALAR
            if (!_isEscutandoPronuncia && _isListening)
              Column(
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text('Sua vez! Fale a palavra:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    _currentRecognized.isEmpty ? 'Ouvindo...' : '"$_currentRecognized"',
                    style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

            if (!_isEscutandoPronuncia && !_isListening && !_isSuccess && !_showNotUnderstood)
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _playPronunciationThenListen,
                    icon: const Icon(Icons.volume_up, size: 24),
                    label: const Text('OUVIR NOVAMENTE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _startListening,
                    icon: const Icon(Icons.mic, size: 24),
                    label: Text(_attempts > 0 ? 'FALAR NOVAMENTE' : 'TOCAR PARA FALAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _attempts > 0 ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),

            if (_showNotUnderstood)
              Column(
                children: [
                  const Icon(Icons.help_outline, color: Colors.orange, size: 48),
                  const SizedBox(height: 8),
                  const Text(
                    'Não entendi, tente falar novamente',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _playPronunciationThenListen,
                    icon: const Icon(Icons.refresh),
                    label: const Text('OUVIR E TENTAR DE NOVO'),
                  ),
                ],
              ),

            if (_isSuccess) const Icon(Icons.check_circle, color: Colors.green, size: 64),

            const SizedBox(height: 16),
            TextButton(
              onPressed: _handleCancel,
              child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
