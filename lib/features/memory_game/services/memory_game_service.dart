// lib/features/memory_game/services/memory_game_service.dart
import 'dart:math';
import '../models/memory_card_model.dart';
import '../models/pictogram_adapter.dart';

class MemoryGameService {
  List<MemoryCardModel> createGameCards(List<MemoryPictogram> pictograms) {
    final cards = <MemoryCardModel>[];

    for (var pictogram in pictograms) {
      cards.add(MemoryCardModel(
        id: '${pictogram.id}_1',
        pictogramId: pictogram.id,
        imagePath: pictogram.imagePath,
        soundPath: pictogram.soundPath ?? '',
      ));
      cards.add(MemoryCardModel(
        id: '${pictogram.id}_2',
        pictogramId: pictogram.id,
        imagePath: pictogram.imagePath,
        soundPath: pictogram.soundPath ?? '',
      ));
    }

    cards.shuffle(Random());
    return cards;
  }
}