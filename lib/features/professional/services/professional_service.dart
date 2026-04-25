import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb; // 🔥 Corrigido para kIsWeb
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../models/child_profile.dart';

class ProfessionalProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

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
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _error = 'Nenhum profissional logado';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final professionalEmail = user.email;

      // 🔥 Na Web ou Mobile, preferimos o Stream para manter o dashboard vivo
      await _childrenSubscription?.cancel();
      _childrenSubscription = _dbService
          .getChildrenStreamByProfessional(professionalEmail)
          .listen((updatedChildren) {
        
        // Ordena por última atividade (quem usou por último fica no topo)
        updatedChildren.sort((a, b) {
          if (a.lastActive == null) return 1;
          if (b.lastActive == null) return -1;
          return b.lastActive!.compareTo(a.lastActive!);
        });

        _children = updatedChildren;
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        _error = 'Erro na sincronização: $e';
        _isLoading = false;
        notifyListeners();
      });

    } catch (e) {
      _error = 'Erro ao carregar dados: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Novo: Verifica se alguma criança está inativa há muito tempo
  bool isChildInactive(ChildProfile child) {
    if (child.lastActive == null) return true;
    final difference = DateTime.now().difference(child.lastActive!).inDays;
    return difference > 3; // Alerta após 3 dias
  }
}
