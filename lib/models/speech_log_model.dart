import 'package:uuid/uuid.dart';

class SpeechLog {
  final String id;
  final String childId; // 🔥 ADICIONADO: Para saber de qual criança é o log
  final String pictogramId;
  final String targetWord;
  final String recognizedWords;
  final bool isSuccess;
  final double confidence;
  final DateTime timestamp;

  SpeechLog({
    String? id,
    required this.childId,
    required this.pictogramId,
    required this.targetWord,
    required this.recognizedWords,
    required this.isSuccess,
    required this.confidence,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'pictogram_id': pictogramId,
      'target_word': targetWord,
      'recognized_words': recognizedWords,
      'is_success': isSuccess ? 1 : 0,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SpeechLog.fromMap(Map<String, dynamic> map) {
    return SpeechLog(
      id: map['id'],
      childId: map['childId'] ?? '',
      pictogramId: map['pictogram_id'],
      targetWord: map['target_word'],
      recognizedWords: map['recognized_words'],
      isSuccess: map['is_success'] == 1,
      confidence: map['confidence']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
