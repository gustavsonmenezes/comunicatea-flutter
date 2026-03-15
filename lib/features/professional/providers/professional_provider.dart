import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../models/auth_user_model.dart';
import '../../../models/child_profile.dart';
import '../../../models/user_progress_model.dart';
import '../../../models/profile_settings_model.dart';

class ProfessionalProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService(); // BANCO REAL!

  AuthUser? _currentProfessional;
  List<ChildProfile> _children = [];
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  AuthUser? get currentProfessional => _currentProfessional;
  List<ChildProfile> get children => _children;
  List<Map<String, dynamic>> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Estatísticas calculadas
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

  // ==================== MÉTODOS PRINCIPAIS ====================

  // CARREGAR DADOS DO BANCO REAL
  Future<void> loadProfessionalData(String professionalId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentProfessional = _authService.currentUser;

      // Se não tiver profissional logado, não carrega
      if (_currentProfessional == null) {
        _error = 'Nenhum profissional logado';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // CARREGA DO BANCO DE DADOS REAL
      debugPrint('Carregando crianças do profissional: $professionalId');
      _children = await _dbService.getChildrenByProfessional(professionalId);
      debugPrint('Crianças carregadas: ${_children.length}');

      _checkAlerts();
    } catch (e) {
      _error = 'Erro ao carregar dados: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ADICIONAR NOVA CRIANÇA (SALVA NO BANCO)
  Future<void> addChild(ChildProfile child) async {
    try {
      debugPrint('Salvando nova criança: ${child.name}');

      // Salva no banco de dados
      await _dbService.saveChild(child);

      // Adiciona na lista local
      _children.add(child);

      // Verifica alertas
      _checkAlerts();

      notifyListeners();

      debugPrint('Criança salva com sucesso!');
    } catch (e) {
      _error = 'Erro ao adicionar criança: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow; // Para o diálogo saber que deu erro
    }
  }

  // REMOVER CRIANÇA
  Future<void> removeChild(String childId) async {
    try {
      debugPrint('Removendo criança: $childId');

      // Remove do banco
      await _dbService.deleteChild(childId);

      // Remove da lista local
      _children.removeWhere((c) => c.id == childId);

      _checkAlerts();
      notifyListeners();

      debugPrint('Criança removida com sucesso!');
    } catch (e) {
      _error = 'Erro ao remover criança: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  // ATUALIZAR CONFIGURAÇÕES (SALVA NO BANCO)
  Future<void> updateChildSettings(String childId, Map<String, dynamic> settings) async {
    try {
      debugPrint('Atualizando configurações da criança: $childId');

      // Primeiro, busca a criança atual
      final childIndex = _children.indexWhere((c) => c.id == childId);
      if (childIndex == -1) {
        throw Exception('Criança não encontrada');
      }

      final child = _children[childIndex];

      // Cria configurações atualizadas
      final updatedSettings = ProfileSettings(
        voiceRate: settings['voiceRate'] ?? child.settings.voiceRate,
        voicePitch: settings['voicePitch'] ?? child.settings.voicePitch,
        highContrast: settings['highContrast'] ?? child.settings.highContrast,
        selectedVoice: settings['selectedVoice'] ?? child.settings.selectedVoice,
      );

      // Atualiza no banco de dados
      await _dbService.updateChildSettings(childId, {
        'voiceRate': updatedSettings.voiceRate,
        'voicePitch': updatedSettings.voicePitch,
        'highContrast': updatedSettings.highContrast,
        'selectedVoice': updatedSettings.selectedVoice,
      });

      // Atualiza na lista local
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

      debugPrint('Configurações atualizadas com sucesso!');
    } catch (e) {
      _error = 'Erro ao atualizar configurações: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  // BUSCAR CRIANÇA ESPECÍFICA (DO BANCO SE NECESSÁRIO)
  Future<ChildProfile?> getChild(String childId) async {
    try {
      debugPrint('Buscando criança: $childId');

      // Tenta da lista local primeiro
      try {
        final localChild = _children.firstWhere((c) => c.id == childId);
        debugPrint('Criança encontrada na lista local');
        return localChild;
      } catch (e) {
        // Se não tiver na lista, busca no banco
        debugPrint('Buscando criança no banco de dados');
        final dbChild = await _dbService.getChild(childId);
        if (dbChild != null) {
          // Adiciona à lista local para cache
          _children.add(dbChild);
          notifyListeners();
        }
        return dbChild;
      }
    } catch (e) {
      _error = 'Erro ao buscar criança: $e';
      debugPrint(_error);
      return null;
    }
  }

  // ATUALIZAR PROGRESSO (USADO QUANDO CRIANÇA USA O APP)
  Future<void> updateChildProgress(String childId, UserProgress progress) async {
    try {
      debugPrint('Atualizando progresso da criança: $childId');

      // Atualiza no banco
      await _dbService.updateChildProgress(childId, progress);

      // Atualiza na lista local
      final index = _children.indexWhere((c) => c.id == childId);
      if (index != -1) {
        final child = _children[index];
        _children[index] = ChildProfile(
          id: child.id,
          name: child.name,
          age: child.age,
          diagnosis: child.diagnosis,
          photoUrl: child.photoUrl,
          responsibleId: child.responsibleId,
          professionalIds: child.professionalIds,
          settings: child.settings,
          progress: progress,
          lastActive: DateTime.now(), // Atualiza último acesso
          createdAt: child.createdAt,
        );

        // Reavalia alertas
        _checkAlerts();
        notifyListeners();
      }

      debugPrint('Progresso atualizado com sucesso!');
    } catch (e) {
      _error = 'Erro ao atualizar progresso: $e';
      debugPrint(_error);
    }
  }

  // ==================== SISTEMA DE ALERTAS ====================

  void _checkAlerts() {
    _alerts.clear();
    final now = DateTime.now();

    for (var child in _children) {
      final daysInactive = now.difference(child.lastActive).inDays;

      // Alerta de inatividade
      if (daysInactive > 3) {
        _alerts.add({
          'id': 'inactive_${child.id}_${now.millisecondsSinceEpoch}',
          'type': 'inactive',
          'childId': child.id,
          'childName': child.name,
          'message': '${child.name} não usa o app há $daysInactive dias',
          'date': now,
          'severity': daysInactive > 7 ? 'high' : 'medium',
          'read': false,
        });
      }

      // Alerta de baixo progresso (menos de 5 sessões em 7 dias)
      if (child.progress.totalSessions < 5 &&
          now.difference(child.createdAt).inDays > 7) {
        _alerts.add({
          'id': 'lowprogress_${child.id}_${now.millisecondsSinceEpoch}',
          'type': 'low_progress',
          'childId': child.id,
          'childName': child.name,
          'message': '${child.name} está com poucas sessões',
          'date': now,
          'severity': 'medium',
          'read': false,
        });
      }

      // Alerta de conquista (positivo!)
      if (child.progress.totalPhrasesBuilt > 100 &&
          !_alerts.any((a) => a['childId'] == child.id && a['type'] == 'milestone')) {
        _alerts.add({
          'id': 'milestone_${child.id}_${now.millisecondsSinceEpoch}',
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

    // Ordenar alertas por data (mais recentes primeiro)
    _alerts.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
  }

  // Marcar alerta como lido
  void markAlertAsRead(String alertId) {
    final index = _alerts.indexWhere((a) => a['id'] == alertId);
    if (index != -1) {
      _alerts[index]['read'] = true;
      notifyListeners();
    }
  }

  // Marcar todos alertas como lidos
  void markAllAlertsAsRead() {
    for (var alert in _alerts) {
      alert['read'] = true;
    }
    notifyListeners();
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Recarregar dados
  Future<void> refreshData() async {
    if (_currentProfessional != null) {
      await loadProfessionalData(_currentProfessional!.id);
    }
  }

  // ==================== MÉTODOS DE UTILIDADE ====================

  // Buscar estatísticas rápidas
  Map<String, dynamic> getStatistics() {
    int totalSessions = _children.fold(0, (sum, c) => sum + c.progress.totalSessions);
    int totalPhrases = _children.fold(0, (sum, c) => sum + c.progress.totalPhrasesBuilt);
    double avgPhrasesPerChild = _children.isEmpty ? 0 : totalPhrases / _children.length;

    return {
      'totalSessions': totalSessions,
      'totalPhrases': totalPhrases,
      'avgPhrasesPerChild': avgPhrasesPerChild,
      'activeToday': activeToday,
      'totalAlerts': totalAlerts,
    };
  }

  // Buscar crianças por status
  List<ChildProfile> getActiveChildren() {
    final today = DateTime.now();
    return _children.where((c) {
      return c.lastActive.year == today.year &&
          c.lastActive.month == today.month &&
          c.lastActive.day == today.day;
    }).toList();
  }

  List<ChildProfile> getInactiveChildren({int days = 7}) {
    final limit = DateTime.now().subtract(Duration(days: days));
    return _children.where((c) => c.lastActive.isBefore(limit)).toList();
  }
}