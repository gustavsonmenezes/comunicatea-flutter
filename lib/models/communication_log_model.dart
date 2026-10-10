import 'package:uuid/uuid.dart';

class CommunicationLog {
  final String id;
  final String childId;
  final List<String> sentence; // Ex: ["Eu quero", "comer", "maçã"]
  final DateTime timestamp;

  CommunicationLog({
    String? id,
    required this.childId,
    required this.sentence,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'sentence': sentence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CommunicationLog.fromMap(Map<String, dynamic> map) {
    return CommunicationLog(
      id: map['id'],
      childId: map['childId'],
      sentence: List<String>.from(map['sentence'] ?? []),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
