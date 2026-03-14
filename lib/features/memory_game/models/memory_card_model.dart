// lib/features/memory_game/models/memory_card_model.dart
class MemoryCardModel {
  final String id;
  final String pictogramId;
  final String imagePath;
  final String soundPath;
  bool isFlipped;
  bool isMatched;

  MemoryCardModel({
    required this.id,
    required this.pictogramId,
    required this.imagePath,
    required this.soundPath,
    this.isFlipped = false,
    this.isMatched = false,
  });

  MemoryCardModel copyWith({
    bool? isFlipped,
    bool? isMatched,
  }) {
    return MemoryCardModel(
      id: id,
      pictogramId: pictogramId,
      imagePath: imagePath,
      soundPath: soundPath,
      isFlipped: isFlipped ?? this.isFlipped,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}