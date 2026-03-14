// lib/features/stickers/models/sticker_model.dart
class StickerModel {
  final String id;
  final String pictogramId;
  final String imagePath;
  final String name;
  final String category;
  bool isUnlocked;
  DateTime? unlockedAt;

  StickerModel({
    required this.id,
    required this.pictogramId,
    required this.imagePath,
    required this.name,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pictogramId': pictogramId,
    'imagePath': imagePath,
    'name': name,
    'category': category,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory StickerModel.fromJson(Map<String, dynamic> json) => StickerModel(
    id: json['id'],
    pictogramId: json['pictogramId'],
    imagePath: json['imagePath'],
    name: json['name'],
    category: json['category'],
    isUnlocked: json['isUnlocked'],
    unlockedAt: json['unlockedAt'] != null
        ? DateTime.parse(json['unlockedAt'])
        : null,
  );
}