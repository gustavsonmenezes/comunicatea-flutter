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
    _initAndPlayAudio();
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

  Future<void> _initAndPlayAudio() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.speak(widget.pictogram.label);
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _currentConfidence = 0.0;
      _currentRecognized = '';
      _showNotUnderstood = false;
    });

    await _speechService.initSpeech();
    if (_speechService.isAvailable) {
      _speechService.startListening(
          onResult: (words) {
            if (mounted) {
              setState(() {
                _currentRecognized = words;
                _currentConfidence = _speechService.confidence;
              });
              _checkMatch(words);
            }
          }
      );

      // Timeout de segurança: Se após 5 segundos não houver sucesso
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isListening && !_isSuccess) {
          _handleFailure(); // 🔥 Agora registra falha no timeout
        }
      });
    }
  }

  void _checkMatch(String spokenWords) {
    if (_isSuccess || spokenWords.isEmpty) return;

    final targetWord = _normalize(widget.pictogram.label);
    final recognized = _normalize(spokenWords);

    bool isMatch = false;
    if (recognized == targetWord) {
      isMatch = true;
    } else if (_currentConfidence > 0.80 && (recognized.contains(targetWord) || targetWord.contains(recognized))) {
      isMatch = true;
    }

    if (isMatch) {
      _handleSuccess();
    }
  }

  // 🔥 NOVA FUNÇÃO: Registra que a criança errou ou não foi entendida
  void _handleFailure() async {
    if (!mounted || _isSuccess) return;

    setState(() {
      _showNotUnderstood = true;
      _isListening = false;
      _attempts++;
    });

    _speechService.stopListening();
    await SoundManager().playError();

    // Registra o log de erro para a IA analisar
    if (_childId != null) {
      await _logService.saveLog(SpeechLog(
        childId: _childId!,
        pictogramId: widget.pictogram.id,
        targetWord: widget.pictogram.label,
        recognizedWords: _currentRecognized.isEmpty ? "(Silêncio/Ruído)" : _currentRecognized,
        isSuccess: false, // ❌ Sucesso: Falso
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
    return result;
  }

  void _handleSuccess() async {
    setState(() { _isSuccess = true; _isListening = false; });
    _speechService.stopListening();
    
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
    Future.delayed(const Duration(seconds: 1), () {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Repita a palavra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Icon(widget.pictogram.icon, size: 64, color: Colors.blue[800]),
            Text(widget.pictogram.label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 24),
            
            if (!_isListening && !_isSuccess && !_showNotUnderstood)
              ElevatedButton.icon(
                onPressed: _startListening,
                icon: const Icon(Icons.mic),
                label: Text(_attempts > 0 ? 'TENTAR NOVAMENTE' : 'TOCAR PARA FALAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _attempts > 0 ? Colors.orange : Colors.green, 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.all(16)
                ),
              ),

            if (_isListening)
              Column(
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(_currentRecognized.isEmpty ? 'Ouvindo...' : '"$_currentRecognized"', style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),

            if (_showNotUnderstood)
              const Column(
                children: [
                  Icon(Icons.help_outline, color: Colors.orange, size: 48),
                  Text('Não entendi bem...', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  Text('Tente falar novamente', style: TextStyle(fontSize: 12)),
                ],
              ),

            if (_isSuccess) const Icon(Icons.check_circle, color: Colors.green, size: 60),
            
            const SizedBox(height: 16),
            TextButton(onPressed: _handleCancel, child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}
