import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/auth_user_model.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  Future<void> init() async {
    await _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Busca dados extras do profissional no Firestore se necessário
      _currentUser = AuthUser(
        id: user.uid,
        username: user.email ?? '',
        displayName: user.displayName ?? 'Profissional',
        role: UserRole.professional, // Na Web/Mobile Profissional, assumimos fono
        createdAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await _loadCurrentUser();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro no login Firebase: $e');
      return false;
    }
  }

  Future<bool> registerProfessional(String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        
        // Opcional: Criar documento na coleção 'professionals' no Firestore
        await FirebaseFirestore.instance.collection('professionals').doc(credential.user!.uid).set({
          'email': email,
          'displayName': displayName,
          'role': 'professional',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _loadCurrentUser();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro no registro Firebase: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}