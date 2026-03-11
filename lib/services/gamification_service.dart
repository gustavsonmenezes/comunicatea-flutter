import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_progress_model.dart';
import '../models/achievement_model.dart';

class GamificationService extends ChangeNotifier {
  // Singleton
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  UserProgress _progress = UserProgress();
  UserProgress get progress => _progress;

  // Chave para o SharedPreferences
  static const String _storageKey = 'user_progress';

  // Inicializa o serviço carregando os dados salvos
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      try {
        _progress = UserProgress.fromJson(jsonDecode(data));
        notifyListeners();
      } catch (e) {
        print('Erro ao carregar progresso: $e');
        _progress = UserProgress();
      }
    }
  }

  // Adiciona uma estrela e verifica conquistas
  Future<void> addStar() async {
    _progress.totalStars++;

    // Verifica se alguma nova conquista foi desbloqueada
    _checkAndUnlockAchievements();

    await _save();
    notifyListeners();
  }

  // Lógica para verificar e desbloquear conquistas
  void _checkAndUnlockAchievements() {
    for (var achievement in appAchievements) {
      // Se a conquista ainda não foi desbloqueada
      if (!_progress.unlockedAchievementIds.contains(achievement.id)) {

        // Critério: Baseado no número de estrelas
        if (_progress.totalStars >= achievement.requiredStars) {
          _progress.unlockedAchievementIds.add(achievement.id);

          // Opcional: Você pode disparar um log ou evento aqui
          debugPrint('🏆 Conquista desbloqueada: ${achievement.title}');
        }
      }
    }
  }

  // Salva os dados localmente
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_progress.toJson()));
    } catch (e) {
      print('Erro ao salvar progresso: $e');
    }
  }

  // Resetar progresso (para testes)
  Future<void> resetProgress() async {
    _progress = UserProgress();
    await _save();
    notifyListeners();
  }
}
