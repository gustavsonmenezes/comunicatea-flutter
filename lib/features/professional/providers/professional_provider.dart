import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../models/child_profile.dart';

class ProfessionalProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  List<ChildProfile> _children = [];
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<ChildProfile>>? _childrenSubscription;

  // Getters
  List<ChildProfile> get children => _children;
  List<Map<String, dynamic>> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalChildren => _children.length;
  int get totalAlerts => _alerts.length;

  int get activeToday {
    final today = DateTime.now();
    return _children.where((c) {
      if (c.lastActive == null) return false;
      return c.lastActive!.year == today.year &&
             c.lastActive!.month == today.month &&
             c.lastActive!.day == today.day;
    }).length;
  }

  @override
  void dispose() {
    _childrenSubscription?.cancel();
    super.dispose();
  }

  // ========================== MÉTODOS PRINCIPAIS ==========================

  Future<void> loadProfessionalData(String professionalId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        _error = 'Nenhum profissional logado';
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (kIsWeb) {
        // Na Web, usamos Stream para tempo real baseado no e-mail
        await _childrenSubscription?.cancel();
        _childrenSubscription = _databaseService
            .getChildrenStreamByProfessional(currentUser.email)
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
        // No Mobile, busca local (SQLite)
        _children = await _databaseService.getChildrenByProfessional(professionalId);
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

  void _checkAlerts() {
    _alerts = [];
    final today = DateTime.now();
    
    for (var child in _children) {
      if (child.lastActive != null) {
        final difference = today.difference(child.lastActive!).inDays;
        if (difference > 3) {
          _alerts.add({
            'childName': child.name,
            'message': 'Sem atividade há $difference dias',
            'severity': 'warning',
          });
        }
      }
    }
  }

  // Adicionado para compatibilidade com ProfessionalDashboardScreen
  Future<void> addChild(ChildProfile child) async {
    try {
      await _databaseService.saveChild(child);
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
}
