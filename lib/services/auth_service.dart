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

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // 🔥 NOVO: Busca o nome do usuário logado
  Future<String> getUserName() async {
    final user = _auth.currentUser;
    if (user == null) return "Usuário";

    try {
      // Tenta buscar em todas as coleções possíveis
      final collections = ['professionals', 'parents', 'children'];
      for (var col in collections) {
        final doc = await _firestore.collection(col).doc(user.uid).get();
        if (doc.exists) {
          return doc.data()?['name'] ?? "Usuário";
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar nome: $e');
    }
    return user.email?.split('@')[0] ?? "Usuário";
  }

  Future<String> getUserType(String uid) async {
    try {
      final parentDoc = await _firestore.collection('parents').doc(uid).get();
      if (parentDoc.exists) return 'parent';

      final profDoc = await _firestore.collection('professionals').doc(uid).get();
      if (profDoc.exists) return 'professional';

      final childDoc = await _firestore.collection('children').doc(uid).get();
      if (childDoc.exists) return 'child';
      
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  Future<String?> getParentChildId(String parentUid) async {
    final doc = await _firestore.collection('parents').doc(parentUid).get();
    return doc.data()?['childId'];
  }

  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registerParent(String email, String password, String name, String childId) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        await _firestore.collection('parents').doc(credential.user!.uid).set({
          'id': credential.user!.uid,
          'name': name,
          'email': email,
          'childId': childId,
          'role': 'parent',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registerProfessional(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
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
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<UserCredential?> registerChild(String email, String password, String name) async {
    String appName = 'ChildRegistration_${DateTime.now().millisecondsSinceEpoch}';
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(name: appName, options: Firebase.app().options);
      UserCredential credential = await FirebaseAuth.instanceFor(app: secondaryApp).createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
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
      return null;
    } finally {
      await secondaryApp?.delete();
    }
  }
}
