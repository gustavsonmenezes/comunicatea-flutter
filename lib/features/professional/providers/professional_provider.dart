import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

      await _childrenSubscription?.cancel();
      _childrenSubscription = _databaseService
          .getChildrenStreamByProfessional(currentUser.email)
          .listen((updatedChildren) async {
        
        _children = updatedChildren;
        
        if (!kIsWeb) {
          for (var child in updatedChildren) {
            await _databaseService.saveChild(child); 
          }
        }
        
        _checkAlerts();
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

  Future<void> addChild(ChildProfile child) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      ChildProfile childToSave = child;

      if (currentUser != null && currentUser.email != null) {
        List<String> emails = List<String>.from(child.professionalEmails ?? []);
        if (!emails.contains(currentUser.email)) {
          emails.add(currentUser.email!);
          childToSave = ChildProfile(
            id: child.id,
            name: child.name,
            email: child.email,
            age: child.age,
            diagnosis: child.diagnosis,
            photoUrl: child.photoUrl,
            professionalIds: child.professionalIds,
            professionalEmails: emails,
            settings: child.settings,
            progress: child.progress,
            lastActive: child.lastActive,
            createdAt: child.createdAt,
          );
        }
      }

      await _databaseService.saveChild(childToSave);
      
      if (!kIsWeb) {
        if (!_children.any((c) => c.id == childToSave.id)) {
          _children.add(childToSave);
        }
        _checkAlerts();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao adicionar criança: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 🔥 NOVO: MÉTODO PARA DELETAR CRIANÇA
  Future<void> deleteChild(String childId) async {
    try {
      // 1. Remove do Firebase
      await FirebaseFirestore.instance.collection('children').doc(childId).delete();
      
      // 2. Remove do SQLite (Mobile)
      if (!kIsWeb) {
        final db = await _databaseService.database;
        if (db != null) {
          await db.delete('children', where: 'id = ?', whereArgs: [childId]);
        }
      }

      // 3. Atualiza a lista local
      _children.removeWhere((c) => c.id == childId);
      _checkAlerts();
      notifyListeners();
      
    } catch (e) {
      _error = 'Erro ao deletar criança: $e';
      notifyListeners();
      rethrow;
    }
  }
}
