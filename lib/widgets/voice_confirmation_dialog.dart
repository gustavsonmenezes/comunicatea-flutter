import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
      _currentConfidence = 0.0;
      _currentRecognized = '';
      _animationController.repeat(reverse: true);
    });

    await _speechService.initSpeech();
    if (_speechService.isAvailable) {
      _speechService.startListening(
          onResult: (words) {
            setState(() {
              _currentRecognized = words;
              _currentConfidence = _speechService.confidence;
            });
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

  // Calcula similaridade entre duas strings (algoritmo de Levenshtein)
  int _levenshteinDistance(String s1, String s2) {
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();

    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
          (i) => List.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= s2.length; j++) matrix[0][j] = j;

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[s1.length][s2.length];
  }

  bool _isSimilar(String word1, String word2, {int maxDistance = 2}) {
    if (word1.isEmpty || word2.isEmpty) return false;

    final clean1 = _removeAccents(word1);
    final clean2 = _removeAccents(word2);

    int distance = _levenshteinDistance(clean1, clean2);

    int maxLen = clean1.length > clean2.length ? clean1.length : clean2.length;

    double similarity = 1.0 - (distance / maxLen);

    print('📊 Similaridade: "$clean1" vs "$clean2" = ${(similarity * 100).toStringAsFixed(0)}%');

    return similarity >= 0.7 || distance <= maxDistance;
  }

  void _checkMatch(String spokenWords) {
    if (_isSuccess || _isFailed) return;

    final targetWord = widget.pictogram.label.toLowerCase().trim();
    final recognized = spokenWords.toLowerCase().trim();

    print('🎤 Reconhecido: "$recognized" | Alvo: "$targetWord" | Confiança: ${(_currentConfidence * 100).toStringAsFixed(0)}%');

    bool isMatch = false;

    // 1. Match exato
    if (recognized == targetWord) {
      isMatch = true;
      print('✅ Match exato');
    }
    // 2. Confiança alta (> 80%)
    else if (_currentConfidence > 0.8) {
      isMatch = true;
      print('✅ Confiança alta: ${(_currentConfidence * 100).toStringAsFixed(0)}%');
    }
    // 3. Palavras alternativas do dicionário
    else {
      final alternatives = _alternativeWords[targetWord] ?? [];
      for (var alt in alternatives) {
        if (recognized.contains(alt) || alt.contains(recognized)) {
          isMatch = true;
          print('✅ Match por dicionário: "$alt"');
          break;
        }
      }
    }

    // 4. Similaridade fonética (algoritmo de Levenshtein)
    if (!isMatch) {
      final recognizedWords = recognized.split(' ');
      for (var word in recognizedWords) {
        if (word.length >= 2 && _isSimilar(word, targetWord)) {
          isMatch = true;
          print('✅ Match por similaridade fonética: "$word" ~ "$targetWord"');
          break;
        }
      }
    }

    // 5. Contém a palavra (com tolerância)
    if (!isMatch) {
      final cleanTarget = _removeAccents(targetWord);
      final cleanRecognized = _removeAccents(recognized);
      if (cleanRecognized.contains(cleanTarget)) {
        isMatch = true;
        print('✅ Match por contém (sem acentos)');
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

    // 🔽 SALVAR LOG DE SUCESSO 🔽
    await _logService.saveLog(SpeechLog(
      pictogramId: widget.pictogram.id,
      targetWord: widget.pictogram.label,
      recognizedWords: _currentRecognized,
      isSuccess: true,
      confidence: _currentConfidence,
    ));

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

    // 🔽 SALVAR LOG DE PULAR (considerar como falha) 🔽
    await _logService.saveLog(SpeechLog(
      pictogramId: widget.pictogram.id,
      targetWord: widget.pictogram.label,
      recognizedWords: 'pular',
      isSuccess: false,
      confidence: 0.0,
    ));

    Navigator.of(context).pop(true);
  }

  void _handleCancel() async {
    // 🔽 SALVAR LOG DE CANCELAMENTO (considerar como falha) 🔽
    await _logService.saveLog(SpeechLog(
      pictogramId: widget.pictogram.id,
      targetWord: widget.pictogram.label,
      recognizedWords: _currentRecognized.isEmpty ? 'cancelado' : _currentRecognized,
      isSuccess: false,
      confidence: _currentConfidence,
    ));
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
                            _currentRecognized.isEmpty
                                ? 'Ouvindo...'
                                : '"$_currentRecognized"',
                            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          if (_currentConfidence > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: FractionallySizedBox(
                                      widthFactor: _currentConfidence,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _currentConfidence > 0.7 ? Colors.green : Colors.orange,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(_currentConfidence * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _currentConfidence > 0.7 ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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
              onPressed: _handleCancel,
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}