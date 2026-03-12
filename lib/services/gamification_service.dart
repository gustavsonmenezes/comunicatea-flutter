// services/gamification_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/user_progress_model.dart';
import '../models/achievement_model.dart';
import '../models/pictogram_model.dart'; // Adicionar import

class GamificationService extends ChangeNotifier {
  // Singleton
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  UserProgress _progress = UserProgress();
  UserProgress get progress => _progress;

  static const String _storageKey = 'user_progress';

  // Listeners para conquistas
  final List<Function(Achievement)> _achievementListeners = [];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      try {
        final json = jsonDecode(data);
        _progress = UserProgress.fromJson(json);
        notifyListeners();
      } catch (e) {
        debugPrint('Erro ao carregar progresso: $e');
        _progress = UserProgress();
      }
    }
  }

  // Adiciona estrela
  Future<void> addStar() async {
    _progress.totalStars++;

    final newAchievements = _checkAndUnlockAchievements();

    await _save();
    notifyListeners();

    // Notifica novas conquistas
    for (var achievement in newAchievements) {
      for (var listener in _achievementListeners) {
        listener(achievement);
      }
    }
  }

  // Registrar uso de categoria
  Future<void> registerCategoryUsage(String categoryId) async {
    _progress.categoryUsage[categoryId] = (_progress.categoryUsage[categoryId] ?? 0) + 1;

    // Verificar conquista de explorador (usou todas categorias - 6 categorias)
    if (_progress.categoryUsage.length >= 6 &&
        !_progress.unlockedAchievementIds.contains('dedicated')) {

      final explorerAchievement = appAchievements.firstWhere(
            (a) => a.id == 'dedicated',
        orElse: () => appAchievements.first,
      );

      if (!_progress.unlockedAchievementIds.contains('dedicated')) {
        _progress.unlockedAchievementIds.add('dedicated');
        _progress.totalStars += 10; // Bônus por explorador

        for (var listener in _achievementListeners) {
          listener(explorerAchievement);
        }
      }
    }

    await _save();
    notifyListeners();
  }

  // Verifica e desbloqueia conquistas
  List<Achievement> _checkAndUnlockAchievements() {
    final newAchievements = <Achievement>[];

    for (var achievement in appAchievements) {
      if (!_progress.unlockedAchievementIds.contains(achievement.id) &&
          achievement.requiredStars > 0 &&
          _progress.totalStars >= achievement.requiredStars) {

        _progress.unlockedAchievementIds.add(achievement.id);
        newAchievements.add(achievement);
        debugPrint('🏆 Conquista desbloqueada: ${achievement.title}');
      }
    }

    return newAchievements;
  }

  void addAchievementListener(Function(Achievement) listener) {
    _achievementListeners.add(listener);
  }

  void removeAchievementListener(Function(Achievement) listener) {
    _achievementListeners.remove(listener);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(_progress.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Erro ao salvar progresso: $e');
    }
  }

  Future<void> resetProgress() async {
    _progress = UserProgress();
    await _save();
    notifyListeners();
  }
}