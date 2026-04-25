import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter para o usuário atual do Firebase
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<String> getUserType(String uid) async {
    try {
      final doc = await _firestore.collection('professionals').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] ?? 'professional';
      }
      
      final childDoc = await _firestore.collection('children').doc(uid).get();
      if (childDoc.exists) {
        return 'child';
      }
      
      return 'unknown';
    } catch (e) {
      debugPrint('Erro ao obter tipo de usuário: $e');
      return 'unknown';
    }
  }

  Future<void> init() async {
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro no login: $e');
      return false;
    }
  }

  // ✅ Método unificado para registro de profissional
  Future<bool> registerProfessional(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);

        await _firestore.collection('professionals').doc(credential.user!.uid).set({
          'id': credential.user!.uid,
          'name': name,
          'email': email,
          'role': 'professional',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro no registro: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  // 🔥 REGISTRA CRIANÇA SEM DESLOGAR O PROFISSIONAL
  Future<UserCredential?> registerChild(String email, String password, String name) async {
    String appName = 'ChildRegistration_${DateTime.now().millisecondsSinceEpoch}';
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      UserCredential credential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        
        // Criar a flag de criança no Firestore
        await _firestore.collection('children').doc(credential.user!.uid).set({
          'id': credential.user!.uid,
          'name': name,
          'email': email,
          'role': 'child',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return credential;
    } catch (e) {
      debugPrint('Erro ao registrar criança: $e');
      return null;
    } finally {
      await secondaryApp?.delete();
    }
  }
}
