import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../models/auth_user_model.dart';
import '../../../models/child_profile.dart';
import '../../../models/user_progress_model.dart';
import '../../../models/profile_settings_model.dart';

class ProfessionalProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

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

  // Carregar dados do profissional
  Future<void> loadProfessionalData(String professionalId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Pega o usuário atual do AuthService
      _currentProfessional = _authService.currentUser;

      // Se não tiver logado, cria um mock para teste
      if (_currentProfessional == null) {
        _currentProfessional = AuthUser(
          id: 'prof_001',
          username: 'dr.silva',
          passwordHash: 'hash',
          role: UserRole.professional,
          displayName: 'Dr. João Silva',
          createdAt: DateTime.now(),
        );
      }

      // Carrega crianças mock para teste
      _loadMockChildren();

      _checkAlerts();
    } catch (e) {
      _error = 'Erro ao carregar dados: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadMockChildren() {
    _children = [
      ChildProfile(
        id: '1',
        name: 'Joãozinho Silva',
        age: 5,
        diagnosis: 'TEA Nível 1',
        photoUrl: null,
        responsibleId: 'resp_001',
        professionalIds: ['prof_001'],
        settings: ProfileSettings(
          voiceRate: 0.5,
          voicePitch: 1.0,
          highContrast: false,
          selectedVoice: 'pt-br-x-abd-local',
        ),
        progress: UserProgress(
          userId: '1',
          totalPhrasesBuilt: 150,
          totalSessions: 25,
          pictogramUsage: {'casa': 10, 'agua': 15, 'comer': 20},
          activeDays: [DateTime.now().subtract(const Duration(days: 1)), DateTime.now()],
          recentSessions: [],
        ),
        lastActive: DateTime.now(),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ChildProfile(
        id: '2',
        name: 'Maria Santos',
        age: 7,
        diagnosis: 'TEA Nível 2',
        photoUrl: null,
        responsibleId: 'resp_002',
        professionalIds: ['prof_001'],
        settings: ProfileSettings(
          voiceRate: 0.4,
          voicePitch: 1.2,
          highContrast: true,
          selectedVoice: 'pt-br-x-abd-local',
        ),
        progress: UserProgress(
          userId: '2',
          totalPhrasesBuilt: 230,
          totalSessions: 40,
          pictogramUsage: {'banheiro': 25, 'agua': 30, 'brincar': 18},
          activeDays: [DateTime.now().subtract(const Duration(days: 1))],
          recentSessions: [],
        ),
        lastActive: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      ChildProfile(
        id: '3',
        name: 'Pedro Oliveira',
        age: 4,
        diagnosis: 'TEA Nível 1',
        photoUrl: null,
        responsibleId: 'resp_003',
        professionalIds: ['prof_001'],
        settings: ProfileSettings(
          voiceRate: 0.6,
          voicePitch: 0.8,
          highContrast: false,
          selectedVoice: 'pt-br-x-abd-local',
        ),
        progress: UserProgress(
          userId: '3',
          totalPhrasesBuilt: 45,
          totalSessions: 8,
          pictogramUsage: {'agua': 5, 'mama': 8, 'nao': 12},
          activeDays: [DateTime.now().subtract(const Duration(days: 5))],
          recentSessions: [],
        ),
        lastActive: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }

  // Buscar criança específica
  Future<ChildProfile?> getChild(String childId) async {
    try {
      return _children.firstWhere((c) => c.id == childId);
    } catch (e) {
      return null;
    }
  }

  // Atualizar configurações
  Future<void> updateChildSettings(String childId, Map<String, dynamic> settings) async {
    try {
      final index = _children.indexWhere((c) => c.id == childId);
      if (index != -1) {
        final child = _children[index];
        final updatedSettings = ProfileSettings(
          voiceRate: settings['voiceRate'] ?? child.settings.voiceRate,
          voicePitch: settings['voicePitch'] ?? child.settings.voicePitch,
          highContrast: settings['highContrast'] ?? child.settings.highContrast,
          selectedVoice: settings['selectedVoice'] ?? child.settings.selectedVoice,
        );

        _children[index] = ChildProfile(
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
    }
  }

  void _checkAlerts() {
    _alerts.clear();
    final now = DateTime.now();

    for (var child in _children) {
      final daysInactive = now.difference(child.lastActive).inDays;

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
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}