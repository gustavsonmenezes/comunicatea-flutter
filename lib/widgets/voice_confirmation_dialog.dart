import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/pictogram_model.dart';
import '../services/speech_recognition_service.dart';
import '../services/sound_manager.dart';
import '../services/gamification_service.dart';

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

  late AnimationController _animationController;
  bool _isSuccess = false;
  bool _isFailed = false;
  bool _isListening = false;
  bool _hasPlayedAudio = false;
  bool _showNotUnderstood = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _initAndPlayAudio();
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
    setState(() {});
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _animationController.repeat(reverse: true);
    });

    await _speechService.initSpeech();
    if (_speechService.isAvailable) {
      _speechService.startListening(
          onResult: (words) {
            _checkMatch(words);
          }
      );
    } else {
      setState(() {
        _isFailed = true;
        _isListening = false;
        _animationController.stop();
      });
    }
  }

  void _checkMatch(String spokenWords) {
    if (_isSuccess || _isFailed) return;

    final targetWord = widget.pictogram.label.toLowerCase().trim();
    final recognized = spokenWords.toLowerCase().trim();

    print('🎤 Reconhecido: "$recognized" | Alvo: "$targetWord"');

    bool isMatch = false;

    // 1. Match exato
    if (recognized == targetWord) {
      isMatch = true;
      print('✅ Match exato');
    }
    // 2. Reconhecido contém a palavra alvo
    else if (recognized.contains(targetWord)) {
      isMatch = true;
      print('✅ Reconhecido contém alvo');
    }
    // 3. Palavra alvo contém o reconhecido (para palavras curtas)
    else if (targetWord.contains(recognized) && recognized.length >= 2) {
      isMatch = true;
      print('✅ Alvo contém reconhecido');
    }
    // 4. Similaridade sem acentos
    else {
      final normalizedTarget = _removeAccents(targetWord);
      final normalizedRecognized = _removeAccents(recognized);

      if (normalizedRecognized.contains(normalizedTarget) ||
          normalizedTarget.contains(normalizedRecognized) && normalizedRecognized.length >= 2) {
        isMatch = true;
        print('✅ Match sem acentos');
      }
    }

    // 5. Verifica palavra por palavra (ex: "quero água" vs "água")
    if (!isMatch) {
      final recognizedWords = recognized.split(' ');
      for (var word in recognizedWords) {
        final cleanWord = _removeAccents(word);
        final cleanTarget = _removeAccents(targetWord);
        if (cleanWord.contains(cleanTarget) || cleanTarget.contains(cleanWord)) {
          isMatch = true;
          print('✅ Match por palavra separada: "$word"');
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

  String _removeAccents(String text) {
    const accents = 'áàãâäéèêëíìîïóòõôöúùûüçÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇ';
    const noAccents = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';

    String result = text;
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], noAccents[i]);
    }
    return result;
  }

  void _handleSuccess() async {
    setState(() {
      _isSuccess = true;
      _isListening = false;
    });

    _speechService.stopListening();
    _animationController.stop();

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

    Navigator.of(context).pop(true);
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
            Icon(widget.pictogram.icon, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              widget.pictogram.label,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _replayAudio,
              icon: const Icon(Icons.volume_up, size: 20),
              label: const Text('Ouvir palavra'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            if (_hasPlayedAudio && !_isSuccess && !_isFailed && !_isListening)
              Column(
                children: [
                  const Text(
                    'Agora repita em voz alta:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _startListening,
                    icon: const Icon(Icons.mic, size: 24),
                    label: const Text('Falar agora'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),

            if (_isListening)
              Column(
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        padding: EdgeInsets.all(8 + (_animationController.value * 8)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.2),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          child: const Icon(Icons.mic, color: Colors.white, size: 40),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _speechService,
                    builder: (context, child) {
                      return Column(
                        children: [
                          Text(
                            _speechService.lastWords.isEmpty
                                ? 'Ouvindo...'
                                : '"${_speechService.lastWords}"',
                            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          if (_showNotUnderstood)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Não entendi. Tente falar: "${widget.pictogram.label}"',
                                style: const TextStyle(color: Colors.orange, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),

            if (_isSuccess)
              const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 60),
                  SizedBox(height: 8),
                  Text('Muito bem!', style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),

            if (_isFailed)
              Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 8),
                  const Text('Não foi possível ouvir', style: TextStyle(color: Colors.red, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isFailed = false;
                        _hasPlayedAudio = true;
                      });
                      _startListening();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: _skipAndAdd,
              child: const Text(
                'Pular (não consegui falar)',
                style: TextStyle(color: Colors.orange),
              ),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}