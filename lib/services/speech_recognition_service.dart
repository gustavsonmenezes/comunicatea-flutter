import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

class SpeechRecognitionService extends ChangeNotifier {
  static final SpeechRecognitionService _instance = SpeechRecognitionService._internal();
  factory SpeechRecognitionService() => _instance;
  SpeechRecognitionService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidence = 0.0;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidence => _confidence;

  Future<void> initSpeech() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'listening') {
            _isListening = true;
          } else {
            _isListening = false;
          }
          notifyListeners();
        },
        onError: (errorNotification) {
          debugPrint('Speech error: ${errorNotification.errorMsg}');
          _isListening = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize speech: $e');
      _isAvailable = false;
    }
    notifyListeners();
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (!_isAvailable) {
      await initSpeech();
    }

    if (_isAvailable) {
      _lastWords = '';
      _confidence = 0.0;
      
      // Usamos listenMode.dictation que é mais robusto para a maioria dos aparelhos
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          if (result.hasConfidenceRating && result.confidence > 0) {
            _confidence = result.confidence;
          }
          debugPrint('Recognized: "$_lastWords" (Conf: $_confidence)');
          onResult(_lastWords);
          notifyListeners();
        },
        localeId: 'pt_BR',
        cancelOnError: false,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      );
      _isListening = true;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
    _isListening = false;
    notifyListeners();
  }
}
