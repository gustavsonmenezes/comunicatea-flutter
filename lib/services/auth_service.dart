// services/auth_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/auth_user_model.dart'; // ← IMPORT CORRIGIDO!

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _usersKey = 'auth_users';
  static const String _currentUserIdKey = 'current_user_id';

  List<AuthUser> _users = [];
  AuthUser? _currentUser;

  List<AuthUser> get users => List.unmodifiable(_users);
  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isProfessional => _currentUser?.role == UserRole.professional;
  bool get isChild => _currentUser?.role == UserRole.child;

  Future<void> init() async {
    await loadUsers();
    await loadCurrentUser();
  }

  Future<void> loadUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_usersKey);

      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        _users = jsonList
            .map((json) => AuthUser.fromJson(json))
            .toList();
      } else {
        // NÃO cria usuário padrão - lista vazia
        _users = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar usuários: $e');
      _users = [];
    }
  }

  // REMOVIDO: _createDefaultUsers() - não será mais usado

  String _hashPassword(String password) => password;
  bool _verifyPassword(String input, String stored) => input == stored;

  Future<bool> login(String username, String password) async {
    try {
      final user = _users.firstWhere(
            (u) => u.username == username,
        orElse: () => throw Exception('Usuário não encontrado'),
      );

      if (_verifyPassword(password, user.passwordHash)) {
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_currentUserIdKey, user.id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro no login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
    notifyListeners();
  }

  Future<bool> registerProfessional(String username, String password, String displayName) async {
    try {
      if (_users.any((u) => u.username == username)) return false;

      final newUser = AuthUser(
        id: 'prof_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        passwordHash: _hashPassword(password),
        role: UserRole.professional,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      _users.add(newUser);
      await _saveUsers();
      _currentUser = newUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserIdKey, newUser.id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro no registro: $e');
      return false;
    }
  }

  Future<bool> registerChild(String username, String password, String displayName, String childProfileId) async {
    try {
      if (_users.any((u) => u.username == username)) return false;

      final newUser = AuthUser(
        id: 'child_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        passwordHash: _hashPassword(password),
        role: UserRole.child,
        childProfileId: childProfileId,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      _users.add(newUser);
      await _saveUsers();
      _currentUser = newUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserIdKey, newUser.id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro no registro: $e');
      return false;
    }
  }

  Future<void> loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString(_currentUserIdKey);

      if (userId != null) {
        _currentUser = _users.firstWhere(
              (u) => u.id == userId,
          orElse: () => throw Exception('Usuário não encontrado'),
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar usuário atual: $e');
      _currentUser = null;
    }
  }

  Future<void> _saveUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _users.map((u) => u.toJson()).toList();
      await prefs.setString(_usersKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Erro ao salvar usuários: $e');
    }
  }
}
