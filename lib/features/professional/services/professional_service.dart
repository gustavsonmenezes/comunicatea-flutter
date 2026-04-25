import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kiWeb;
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../models/auth_user_model.dart';
import '../../../models/child_profile.dart';

class ProfessionalProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  AuthUser? _currentProfessional;
  List<ChildProfile> _children = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<ChildProfile>>? _childrenSubscription;

  // Getters
  List<ChildProfile> get children => _children;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalChildren => _children.length;

  @override
  void dispose() {
    _childrenSubscription?.cancel();
    super.dispose();
  }

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

      // AJUSTE AQUI: Usando o E-MAIL para sincronizar entre Web e Mobile
      final professionalEmail = _currentProfessional!.email;

      if (kiWeb) {
        // Na Web, usamos Stream para tempo real baseado no e-mail
        _childrenSubscription?.cancel();
        _childrenSubscription = _dbService
            .getChildrenStreamByProfessional(professionalEmail)
            .listen((updatedChildren) {
          _children = updatedChildren;
          _isLoading = false;
          notifyListeners();
        }, onError: (e) {
          _error = 'Erro ao carregar dados: $e';
          _isLoading = false;
          notifyListeners();
        });
      } else {
        // No Mobile, busca local ou via ID (ajustar conforme sua DatabaseService)
        _children = await _dbService.getChildrenByProfessional(professionalId);
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao carregar dados: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}
