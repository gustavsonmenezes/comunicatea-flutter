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
  String? _lastError;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidence => _confidence;
  String? get lastError => _lastError;

  Future<bool> initSpeech() async {
    _lastError = null;
    try {
      if (_speech.isAvailable) {
        _isAvailable = true;
        return true;
      }
      _isAvailable = await _speech.initialize(
        debugLogging: kDebugMode,
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'listening') {
            _isListening = true;
          } else if (status == 'notListening' || status == 'done') {
            _isListening = false;
          }
          notifyListeners();
        },
        onError: (errorNotification) {
          debugPrint('Speech error: ${errorNotification.errorMsg} (permanent: ${errorNotification.permanent})');
          _lastError = errorNotification.errorMsg;
          _isListening = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize speech: $e');
      _lastError = e.toString();
      _isAvailable = false;
    }
    notifyListeners();
    return _isAvailable;
  }

  double _soundLevel = -2.0;
  double get soundLevel => _soundLevel;

  Future<bool> startListening({required Function(String) onResult}) async {
    _lastError = null;

    if (_isListening) {
      await cancelListening();
    }

    if (!_isAvailable || !_speech.isAvailable) {
      await initSpeech();
    }

    if (_isAvailable) {
      _lastWords = '';
      _confidence = 0.0;
      _soundLevel = -2.0;

      String targetLocale = 'pt_BR';
      try {
        final systemLocale = await _speech.systemLocale();
        if (systemLocale != null) {
          final locales = await _speech.locales();
          bool hasPtBr = locales.any((loc) => loc.localeId.startsWith('pt'));
          if (!hasPtBr) {
            targetLocale = systemLocale.localeId;
          }
        }
      } catch (e) {
        debugPrint('Erro ao obter locales de voz: $e');
      }

      try {
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
          onSoundLevelChange: (level) {
            _soundLevel = level;
            notifyListeners();
          },
          localeId: targetLocale,
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            cancelOnError: false,
            listenMode: kIsWeb ? stt.ListenMode.dictation : stt.ListenMode.confirmation,
          ),
          listenFor: const Duration(seconds: 12),
          pauseFor: const Duration(seconds: 4),
        );
        _isListening = true;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Error starting listening: $e');
        _lastError = e.toString();
        _isListening = false;
        notifyListeners();
        return false;
      }
    } else {
      debugPrint('Speech recognition is not available');
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
    _isListening = false;
    notifyListeners();
  }

  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('Error cancelling speech: $e');
    }
    _isListening = false;
    notifyListeners();
  }
}
