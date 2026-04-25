import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/child_profile.dart';
import '../models/profile_settings_model.dart';
import '../models/user_progress_model.dart';
import 'database_service.dart';

class ProfileService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService();

  ChildProfile? _currentChild;
  ChildProfile? get currentChild => _currentChild;

  // Seleciona a criança atual e salva no estado
  void selectChild(ChildProfile child) {
    _currentChild = child;
    notifyListeners();
  }

  // Cria um novo perfil de criança
  Future<bool> createChildProfile({
    required String name,
    required int age,
    required String diagnosis,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Gera um ID único para a criança
      final childId = _firestore.collection('children').doc().id;

      final newChild = ChildProfile(
        id: childId,
        name: name,
        age: age,
        diagnosis: diagnosis,
        professionalIds: [user.uid],
        professionalEmails: [user.email ?? ''],
        settings: ProfileSettings(), // Adicionado para bater com o modelo
        progress: UserProgress(userId: childId), // Adicionado para bater com o modelo
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Salva usando saveChild (que já lida com SQLite e Cloud)
      await _dbService.saveChild(newChild);

      _currentChild = newChild;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao criar perfil: $e');
      return false;
    }
  }

  // Atualiza o perfil da criança
  Future<bool> updateChildProfile(ChildProfile child) async {
    try {
      await _dbService.saveChild(child);

      _currentChild = child;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar perfil: $e');
      return false;
    }
  }

  // Limpa a seleção
  void clearSelection() {
    _currentChild = null;
    notifyListeners();
  }
}
