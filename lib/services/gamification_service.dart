// lib/services/gamification_service.dart - VERSÃO CORRIGIDA PRONTA PARA COPIAR E COLAR
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/user_progress_model.dart';
import '../models/achievement_model.dart';

class GamificationService extends ChangeNotifier {
  // Singleton
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  UserProgress _progress = UserProgress(userId: 'temp_user');
  UserProgress get progress => _progress;

  String? _currentProfileId;

  static const String _storageKeyPrefix = 'user_progress_';

  final List<Function(Achievement)> _achievementListeners = [];

  Future<void> initializeForProfile(String profileId) async {
    _currentProfileId = profileId;
    await loadProgressForProfile(profileId);
  }

  Future<void> loadProgressForProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('$_storageKeyPrefix$profileId');

      if (data != null) {
        _progress = UserProgress.fromJson(jsonDecode(data));
      } else {
        _progress = UserProgress(userId: profileId);
      }

      _currentProfileId = profileId;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar progresso do perfil $profileId: $e');
      _progress = UserProgress(userId: profileId);
    }
  }

  Future<void> deleteProgressForProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_storageKeyPrefix$profileId');
    } catch (e) {
      debugPrint('Erro ao excluir progresso: $e');
    }
  }

  Future<void> addStar() async {
    if (_currentProfileId == null) return;

    _progress.totalStars++;

    final newAchievements = _checkAndUnlockAchievements();

    await _save();
    notifyListeners();

    for (var achievement in newAchievements) {
      for (var listener in _achievementListeners) {
        listener(achievement);
      }
    }
  }

  Future<void> registerCategoryUsage(String categoryId) async {
    if (_currentProfileId == null) return;

    _progress.categoryUsage[categoryId] = (_progress.categoryUsage[categoryId] ?? 0) + 1;

    if (_progress.categoryUsage.length >= 6 &&
        !_progress.unlockedAchievementIds.contains('dedicated')) {

      final explorerAchievement = appAchievements.firstWhere(
            (a) => a.id == 'dedicated',
        orElse: () => appAchievements.first,
      );

      if (!_progress.unlockedAchievementIds.contains('dedicated')) {
        _progress.unlockedAchievementIds.add('dedicated');
        _progress.totalStars += 10;

        for (var listener in _achievementListeners) {
          listener(explorerAchievement);
        }
      }
    }

    await _save();
    notifyListeners();
  }

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
    if (_currentProfileId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(_progress.toJson());
      await prefs.setString('$_storageKeyPrefix$_currentProfileId', jsonString);
    } catch (e) {
      debugPrint('Erro ao salvar progresso: $e');
    }
  }

  Future<void> resetProgress() async {
    _progress = UserProgress(userId: _currentProfileId ?? 'temp_user');
    await _save();
    notifyListeners();
  }
}
