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

  late AnimationController _animationController;
  bool _isSuccess = false;
  bool _isFailed = false;
  bool _isListening = false;
  bool _hasPlayedAudio = false;
  bool _showNotUnderstood = false;
  double _currentConfidence = 0.0;
  String _currentRecognized = '';
  String? _childId;

  // Dicionário de palavras alternativas para cada pictograma
  final Map<String, List<String>> _alternativeWords = {
    'água': ['agua', 'awa', 'águ', 'aagua'],
    'comida': ['comida', 'comer', 'come', 'comid', 'cumida'],
    'banheiro': ['banheiro', 'banheiro', 'banhe', 'banhero', 'banheiru'],
    'feliz': ['feliz', 'feliz', 'fliz', 'felis'],
    'triste': ['triste', 'trist', 'trishte', 'tristi'],
    'brincar': ['brincar', 'brinca', 'brincá', 'brincar'],
    'dormir': ['dormir', 'dormi', 'dorme', 'dormir'],
    'mamãe': ['mamae', 'mama', 'mamãe', 'mamai'],
    'papai': ['papai', 'papa', 'papae', 'papay'],
    'ajuda': ['ajuda', 'ajudar', 'ajuda', 'ajuda'],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _initAndPlayAudio();
    _loadChildId();
  }

  Future<void> _loadChildId() async {
    final prefs = await SharedPreferences.getInstance();
    _childId = prefs.getString('currentChildId');
    if (_childId == null) {
      _childId = FirebaseAuth.instance.currentUser?.uid;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speechService.cancelListening();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initAndPlayAudio() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(widget.pictogram.label);
    _hasPlayedAudio = true;
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() {});
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _currentConfidence = 0.0;
      _currentRecognized = '';
      _animationController.repeat(reverse: true);
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
    } else {
      if (mounted) {
        setState(() {
          _isFailed = true;
          _isListening = false;
          _animationController.stop();
        });
      }
    }
  }

  void _checkMatch(String spokenWords) {
    if (_isSuccess || _isFailed) return;

    final targetWord = widget.pictogram.label.toLowerCase().trim();
    final recognized = spokenWords.toLowerCase().trim();

    debugPrint('🎤 Reconhecido: "$recognized" | Alvo: "$targetWord" | Confiança: ${(_currentConfidence * 100).toStringAsFixed(0)}%');

    bool isMatch = false;

    if (recognized == targetWord) {
      isMatch = true;
    } else if (_currentConfidence > 0.8) {
      isMatch = true;
    } else {
      final alternatives = _alternativeWords[targetWord] ?? [];
      for (var alt in alternatives) {
        if (recognized.contains(alt) || alt.contains(recognized)) {
          isMatch = true;
          break;
        }
      }
    }

    if (isMatch) {
      _handleSuccess();
    } else if (recognized.isNotEmpty && !_isFailed) {
      setState(() {
        _showNotUnderstood = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showNotUnderstood = false;
          });
        }
      });
    }
  }

  void _handleSuccess() async {
    setState(() {
      _isSuccess = true;
      _isListening = false;
    });

    _speechService.stopListening();
    _animationController.stop();

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

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  void _skipAndAdd() async {
    _speechService.stopListening();
    _animationController.stop();

    if (_childId != null) {
      await _logService.saveLog(SpeechLog(
        childId: _childId!,
        pictogramId: widget.pictogram.id,
        targetWord: widget.pictogram.label,
        recognizedWords: 'pular',
        isSuccess: false,
        confidence: 0.0,
      ));
    }

    Navigator.of(context).pop(true);
  }

  void _handleCancel() async {
    if (_childId != null) {
      await _logService.saveLog(SpeechLog(
        childId: _childId!,
        pictogramId: widget.pictogram.id,
        targetWord: widget.pictogram.label,
        recognizedWords: _currentRecognized.isEmpty ? 'cancelado' : _currentRecognized,
        isSuccess: false,
        confidence: _currentConfidence,
      ));
    }
    Navigator.of(context).pop(false);
  }

  void _replayAudio() async {
    await _flutterTts.speak(widget.pictogram.label);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Escute e repita',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              width: 120,
              child: widget.pictogram.assetPath != null
                  ? Image.asset(widget.pictogram.assetPath!, fit: BoxFit.contain)
                  : Icon(widget.pictogram.icon, size: 80, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 8),
            Text(widget.pictogram.label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _replayAudio,
              icon: const Icon(Icons.volume_up, size: 20),
              label: const Text('Ouvir palavra'),
            ),
            const SizedBox(height: 24),
            if (_hasPlayedAudio && !_isSuccess && !_isFailed && !_isListening)
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _startListening,
                    icon: const Icon(Icons.mic),
                    label: const Text('Tentar falar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                  TextButton(onPressed: _skipAndAdd, child: const Text('Pular e adicionar mesmo assim')),
                ],
              ),
            if (_isListening)
              Column(
                children: [
                  const Icon(Icons.mic, color: Colors.blue, size: 40),
                  const SizedBox(height: 16),
                  Text(_currentRecognized.isEmpty ? 'Ouvindo...' : '"$_currentRecognized"'),
                  if (_showNotUnderstood) const Text('Não entendi, tente novamente', style: TextStyle(color: Colors.orange)),
                ],
              ),
            if (_isSuccess) const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 24),
            TextButton(onPressed: _handleCancel, child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}
