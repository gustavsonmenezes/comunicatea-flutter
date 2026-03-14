// lib/features/stickers/services/sticker_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sticker_model.dart';

class StickerService {
  static const String _stickersKey = 'user_stickers';

  Future<List<StickerModel>> getStickers(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('${_stickersKey}_$profileId');

    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => StickerModel.fromJson(json)).toList();
    }

    // Retorna lista vazia se não tiver stickers
    return [];
  }

  Future<void> unlockSticker(String profileId, String pictogramId) async {
    final stickers = await getStickers(profileId);
    final index = stickers.indexWhere((s) => s.pictogramId == pictogramId);

    if (index != -1 && !stickers[index].isUnlocked) {
      stickers[index].isUnlocked = true;
      stickers[index].unlockedAt = DateTime.now();
      await _saveStickers(profileId, stickers);
    }
  }

  Future<void> _saveStickers(String profileId, List<StickerModel> stickers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = stickers.map((s) => s.toJson()).toList();
    await prefs.setString('${_stickersKey}_$profileId', jsonEncode(jsonList));
  }
}