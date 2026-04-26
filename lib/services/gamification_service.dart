import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  String? _currentChildId;
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _storageKeyPrefix = 'user_progress_';
  final List<Function(Achievement)> _achievementListeners = [];

  // 🔥 Alias para compatibilidade com códigos antigos
  Future<void> initializeForProfile(String profileId) async {
    await initializeForChild(profileId);
  }

  // 🔥 Mantendo para compatibilidade
  void setCurrentChild(String childId) {
    _currentChildId = childId;
  }

  Future<void> initializeForChild(String childId) async {
    _currentChildId = childId;
    debugPrint('🎮 GamificationService: Inicializando para Criança ID: $childId');

    try {
      final doc = await _firestore.collection('children').doc(childId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('progress')) {
          _progress = UserProgress.fromJson(data['progress']);
          debugPrint('✅ GamificationService: Progresso carregado do Cloud. Estrelas: ${_progress.totalStars}');
        } else {
          _progress = UserProgress(userId: childId);
        }
      } else {
        _progress = UserProgress(userId: childId);
      }

      await _saveLocal();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ GamificationService: Erro ao carregar do Cloud, usando local: $e');
      await _loadLocal(childId);
    }
  }

  Future<void> addStar() async {
    if (_currentChildId == null) return;
    
    _progress.totalStars++;
    _progress.totalPhrasesBuilt++; 
    
    final newAchievements = _checkAndUnlockAchievements();
    
    await _saveLocal();
    notifyListeners();

    for (var achievement in newAchievements) {
      for (var listener in _achievementListeners) {
        listener(achievement);
      }
    }

    await _syncData();
  }

  // 🔥 Restaurando o método de registro de categoria
  Future<void> registerCategoryUsage(String categoryId) async {
    if (_currentChildId == null) return;

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

    await _saveLocal();
    notifyListeners();
    await _syncData();
  }

  Future<void> _syncData() async {
    if (_currentChildId == null || _currentChildId!.startsWith('temp_')) return;

    try {
      await _firestore.collection('children').doc(_currentChildId).set({
        'progress': _progress.toJson(),
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('☁️ GamificationService: Sincronizado com Firestore.');
    } catch (e) {
      debugPrint('❌ GamificationService: Erro na sincronização: $e');
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

  Future<void> _saveLocal() async {
    if (_currentChildId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_storageKeyPrefix$_currentChildId', jsonEncode(_progress.toJson()));
    } catch (e) {
      debugPrint('Erro ao salvar progresso local: $e');
    }
  }

  Future<void> _loadLocal(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('$_storageKeyPrefix$childId');
    if (data != null) {
      _progress = UserProgress.fromJson(jsonDecode(data));
      notifyListeners();
    }
  }
}
