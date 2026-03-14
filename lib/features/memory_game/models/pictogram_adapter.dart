// lib/features/memory_game/models/pictogram_adapter.dart
import '../../../models/pictogram_model.dart';

// Classe adaptadora para usar no jogo da memória
class MemoryPictogram {
  final String id;
  final String name;
  final String imagePath;
  final String category;
  final String? soundPath;

  MemoryPictogram({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.category,
    this.soundPath,
  });

  // Converte do seu Pictogram para MemoryPictogram
  factory MemoryPictogram.fromPictogram(Pictogram pictogram, String categoryId, String categoryName) {
    // Como seu Pictogram não tem imagePath, usamos o ícone como fallback
    return MemoryPictogram(
      id: pictogram.id,
      name: pictogram.label,
      imagePath: 'icon', // Marcador para usar ícone
      category: categoryName,
    );
  }

  // Converte de PictogramCategory
  factory MemoryPictogram.fromCategory(PictogramCategory category, Pictogram pictogram) {
    return MemoryPictogram(
      id: pictogram.id,
      name: pictogram.label,
      imagePath: 'icon',
      category: category.name,
    );
  }
}