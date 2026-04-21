import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../models/auth_user_model.dart';
import '../../../models/child_profile.dart';
import '../../../models/user_progress_model.dart';
import '../../../models/profile_settings_model.dart';

class ProfessionalProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  AuthUser? _currentProfessional;
  List<ChildProfile> _children = [];
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = false;
  String? _error;
  
  // Stream Subscription para Web
  StreamSubscription<List<ChildProfile>>? _childrenSubscription;

  // Getters
  AuthUser? get currentProfessional => _currentProfessional;
  List<ChildProfile> get children => _children;
  List<Map<String, dynamic>> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalChildren => _children.length;

  int get activeToday {
    final today = DateTime.now();
    return _children.where((c) {
      return c.lastActive.year == today.year &&
          c.lastActive.month == today.month &&
          c.lastActive.day == today.day;
    }).length;
  }

  int get totalAlerts => _alerts.length;

  @override
  void dispose() {
    _childrenSubscription?.cancel();
    super.dispose();
  }

  // ==================== MÉTODOS PRINCIPAIS ====================

  Future<void> loadProfessionalData(String professionalId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentProfessional = _authService.currentUser;

      if (_currentProfessional == null) {
        _error = 'Nenhum profissional logado';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Se for Web, usamos Stream para tempo real
      if (kIsWeb) {
        await _childrenSubscription?.cancel();
        _childrenSubscription = _dbService
            .getChildrenStreamByProfessional(professionalId)
            .listen((updatedChildren) {
          _children = updatedChildren;
          _checkAlerts();
          _isLoading = false;
          notifyListeners();
        }, onError: (e) {
          _error = 'Erro no Stream: $e';
          _isLoading = false;
          notifyListeners();
        });
      } else {
        // Se for Mobile, busca normal (SQLite)
        _children = await _dbService.getChildrenByProfessional(professionalId);
        _checkAlerts();
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao carregar dados: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addChild(ChildProfile child) async {
    try {
      await _dbService.saveChild(child);
      if (!kIsWeb) {
        _children.add(child);
        _checkAlerts();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao adicionar criança: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeChild(String childId) async {
    try {
      await _dbService.deleteChild(childId);
      if (!kIsWeb) {
        _children.removeWhere((c) => c.id == childId);
        _checkAlerts();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao remover criança: $e';
      notifyListeners();
    }
  }

  // BUSCAR CRIANÇA ESPECÍFICA (RESTAURADO)
  Future<ChildProfile?> getChild(String childId) async {
    try {
      // Tenta da lista local primeiro
      try {
        final localChild = _children.firstWhere((c) => c.id == childId);
        return localChild;
      } catch (e) {
        // Se não tiver na lista, busca no banco
        final dbChild = await _dbService.getChild(childId);
        if (dbChild != null && !kIsWeb) {
          _children.add(dbChild);
          notifyListeners();
        }
        return dbChild;
      }
    } catch (e) {
      _error = 'Erro ao buscar criança: $e';
      notifyListeners();
      return null;
    }
  }

  // ATUALIZAR CONFIGURAÇÕES (RESTAURADO)
  Future<void> updateChildSettings(String childId, Map<String, dynamic> settings) async {
    try {
      // Primeiro, busca a criança atual
      final childIndex = _children.indexWhere((c) => c.id == childId);
      if (childIndex == -1) {
        throw Exception('Criança não encontrada');
      }

      final child = _children[childIndex];

      // Atualiza no banco de dados
      await _dbService.updateChildSettings(childId, settings);

      // Se não for Web (onde o stream atualiza), atualiza localmente
      if (!kIsWeb) {
        final updatedSettings = ProfileSettings(
          voiceRate: settings['voiceRate'] ?? child.settings.voiceRate,
          voicePitch: settings['voicePitch'] ?? child.settings.voicePitch,
          highContrast: settings['highContrast'] ?? child.settings.highContrast,
          selectedVoice: settings['selectedVoice'] ?? child.settings.selectedVoice,
        );

        _children[childIndex] = ChildProfile(
          id: child.id,
          name: child.name,
          age: child.age,
          diagnosis: child.diagnosis,
          photoUrl: child.photoUrl,
          responsibleId: child.responsibleId,
          professionalIds: child.professionalIds,
          settings: updatedSettings,
          progress: child.progress,
          lastActive: child.lastActive,
          createdAt: child.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao atualizar configurações: $e';
      notifyListeners();
      rethrow;
    }
  }

  void _checkAlerts() {
    _alerts.clear();
    final now = DateTime.now();

    for (var child in _children) {
      final daysInactive = now.difference(child.lastActive).inDays;

      if (daysInactive > 3) {
        _alerts.add({
          'id': 'inactive_${child.id}',
          'type': 'inactive',
          'childId': child.id,
          'childName': child.name,
          'message': '${child.name} não usa o app há $daysInactive dias',
          'date': now,
          'severity': daysInactive > 7 ? 'high' : 'medium',
          'read': false,
        });
      }

      if (child.progress.totalPhrasesBuilt > 100) {
        _alerts.add({
          'id': 'milestone_${child.id}',
          'type': 'milestone',
          'childId': child.id,
          'childName': child.name,
          'message': '🎉 ${child.name} fez mais de 100 frases!',
          'date': now,
          'severity': 'positive',
          'read': false,
        });
      }
    }
    _alerts.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
  }

  Future<void> refreshData() async {
    if (_currentProfessional != null) {
      await loadProfessionalData(_currentProfessional!.id);
    }
  }
}