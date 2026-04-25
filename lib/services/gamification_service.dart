import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/user_progress_model.dart';
import '../models/achievement_model.dart';
import 'database_service.dart';
import 'sync_service.dart';
import 'auth_service.dart';

class GamificationService extends ChangeNotifier {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  UserProgress _progress = UserProgress(userId: 'temp_user');
  UserProgress get progress => _progress;

  String? _currentProfileId;
  String? _currentChildId;
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();
  final AuthService _authService = AuthService();

  static const String _storageKeyPrefix = 'user_progress_';
  final List<Function(Achievement)> _achievementListeners = [];

  Future<void> initializeForProfile(String profileId) async {
    _currentProfileId = profileId;
    
    // Tenta carregar do Firestore se estiver logado como criança
    final user = _authService.getCurrentUser();
    if (user != null) {
      final userType = await _authService.getUserType(user.uid);
      if (userType == 'child') {
        _currentChildId = user.uid;
        final cloudProgress = await _syncService.fetchProgress(user.uid);
        if (cloudProgress != null) {
          _progress = cloudProgress;
          await _save(); // Sincroniza cache local
        }
      }
    }

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
        final loadedProgress = UserProgress.fromJson(json);
        _progress = UserProgress(
          userId: loadedProgress.userId,
          totalSessions: loadedProgress.totalSessions,
          totalPhrasesBuilt: loadedProgress.totalPhrasesBuilt,
          activeDays: List.from(loadedProgress.activeDays),
          pictogramUsage: Map<String, int>.from(loadedProgress.pictogramUsage),
          totalStars: loadedProgress.totalStars,
          categoryUsage: Map<String, int>.from(loadedProgress.categoryUsage),
          unlockedAchievementIds: List.from(loadedProgress.unlockedAchievementIds),
        );
      } else if (_progress.userId == 'temp_user' || _progress.userId != profileId) {
        _progress = UserProgress(userId: profileId);
      }

      _currentProfileId = profileId;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar progresso: $e');
      if (_progress.userId == 'temp_user') {
        _progress = UserProgress(userId: profileId);
      }
    }
  }

  Future<void> addStar() async {
    if (_currentProfileId == null) return;
    _progress.totalStars++;
    _progress.totalPhrasesBuilt++; 
    
    final newAchievements = _checkAndUnlockAchievements();
    await _save();
    notifyListeners();

    for (var achievement in newAchievements) {
      for (var listener in _achievementListeners) {
        listener(achievement);
      }
    }

    await _syncData();
  }

  Future<void> registerCategoryUsage(String categoryId) async {
    if (_currentProfileId == null) return;

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

    await _syncData();
  }

  Future<void> _syncData() async {
    // Se não tiver childId definido, tenta pegar o UID do usuário logado
    if (_currentChildId == null) {
      final user = _authService.getCurrentUser();
      if (user != null) {
        _currentChildId = user.uid;
      }
    }

    if (_currentChildId != null && !_currentChildId!.startsWith('temp_')) {
      // Salva no SQLite e Firestore (via DatabaseService)
      await _dbService.updateChildProgress(_currentChildId!, _progress);
      // Sincroniza especificamente para o Firestore (via SyncService)
      await _syncService.syncProgress(_currentChildId!, _progress);
    } else {
      debugPrint('⚠️ Sincronização ignorada: Usuário não identificado ou ID temporário ($_currentChildId)');
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
      debugPrint('Erro ao salvar progresso local: $e');
    }
  }
}
