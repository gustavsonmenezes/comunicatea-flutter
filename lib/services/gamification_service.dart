import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/user_progress_model.dart';
import '../models/achievement_model.dart';
import 'database_service.dart';

class GamificationService extends ChangeNotifier {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  UserProgress _progress = UserProgress(userId: 'temp_user');
  UserProgress get progress => _progress;

  String? _currentProfileId;
  String? _currentChildId;
  final DatabaseService _dbService = DatabaseService();

  static const String _storageKeyPrefix = 'user_progress_';
  final List<Function(Achievement)> _achievementListeners = [];

  Future<void> initializeForProfile(String profileId) async {
    _currentProfileId = profileId;
    await loadProgressForProfile(profileId);
  }

  void setCurrentChild(String childId) {
    _currentChildId = childId;
  }

  Future<void> loadProgressForProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('$_storageKeyPrefix$profileId');

      if (data != null) {
        final json = jsonDecode(data);
        _progress = UserProgress.fromJson(json);
        // ✅ Garante que os mapas sejam modificáveis
        _progress = UserProgress(
          userId: _progress.userId,
          totalSessions: _progress.totalSessions,
          totalPhrasesBuilt: _progress.totalPhrasesBuilt,
          activeDays: List.from(_progress.activeDays),
          pictogramUsage: Map<String, int>.from(_progress.pictogramUsage),
          totalStars: _progress.totalStars,
          categoryUsage: Map<String, int>.from(_progress.categoryUsage),
          unlockedAchievementIds: List.from(_progress.unlockedAchievementIds),
        );
      } else {
        _progress = UserProgress(userId: profileId);
      }

      _currentProfileId = profileId;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar progresso: $e');
      _progress = UserProgress(userId: profileId);
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

    if (_currentChildId != null) {
      await _dbService.updateChildProgress(_currentChildId!, _progress);
    }
  }

  Future<void> registerCategoryUsage(String categoryId) async {
    if (_currentProfileId == null) return;

    // ✅ Proteção extra: garante que o mapa é modificável antes de alterar
    final usage = Map<String, int>.from(_progress.categoryUsage);
    usage[categoryId] = (usage[categoryId] ?? 0) + 1;
    
    _progress = UserProgress(
      userId: _progress.userId,
      totalSessions: _progress.totalSessions,
      totalPhrasesBuilt: _progress.totalPhrasesBuilt,
      activeDays: _progress.activeDays,
      pictogramUsage: _progress.pictogramUsage,
      totalStars: _progress.totalStars,
      categoryUsage: usage,
      unlockedAchievementIds: _progress.unlockedAchievementIds,
    );

    await _save();
    notifyListeners();

    if (_currentChildId != null) {
      await _dbService.updateChildProgress(_currentChildId!, _progress);
    }
  }

  List<Achievement> _checkAndUnlockAchievements() {
    final newAchievements = <Achievement>[];
    for (var achievement in appAchievements) {
      if (!_progress.unlockedAchievementIds.contains(achievement.id) &&
          achievement.requiredStars > 0 &&
          _progress.totalStars >= achievement.requiredStars) {
        _progress.unlockedAchievementIds.add(achievement.id);
        newAchievements.add(achievement);
      }
    }
    return newAchievements;
  }

  void addAchievementListener(Function(Achievement) listener) => _achievementListeners.add(listener);
  void removeAchievementListener(Function(Achievement) listener) => _achievementListeners.remove(listener);

  Future<void> _save() async {
    if (_currentProfileId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_storageKeyPrefix$_currentProfileId', jsonEncode(_progress.toJson()));
    } catch (e) {
      debugPrint('Erro ao salvar progresso: $e');
    }
  }
}