// services/profile_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../features/profiles/models/profile_model.dart';
import 'gamification_service.dart';

class ProfileService extends ChangeNotifier {
  // Singleton
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  static const String _profilesKey = 'user_profiles';
  static const String _currentProfileIdKey = 'current_profile_id';

  List<UserProfile> _profiles = [];
  UserProfile? _currentProfile;

  List<UserProfile> get profiles => List.unmodifiable(_profiles);
  UserProfile? get currentProfile => _currentProfile;
  bool get hasActiveProfile => _currentProfile != null;

  Future<void> init() async {
    await loadProfiles();
    await loadCurrentProfile();
  }

  Future<void> loadProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_profilesKey);

      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        _profiles = jsonList
            .map((json) => UserProfile.fromJson(json))
            .toList();
      } else {
        _profiles = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar perfis: $e');
      _profiles = [];
    }
  }

  Future<void> loadCurrentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? profileId = prefs.getString(_currentProfileIdKey);

      if (profileId != null) {
        try {
          _currentProfile = _profiles.firstWhere((p) => p.id == profileId);
          await updateProfileLastUsed(_currentProfile!.id);
        } catch (e) {
          _currentProfile = null;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar perfil atual: $e');
      _currentProfile = null;
    }
  }

  Future<bool> createProfile(String name, String avatarEmoji) async {
    try {
      final newProfile = UserProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        avatarEmoji: avatarEmoji,
        createdAt: DateTime.now(),
      );

      _profiles.add(newProfile);
      await _saveProfiles();

      await GamificationService().initializeForProfile(newProfile.id);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao criar perfil: $e');
      return false;
    }
  }

  Future<bool> selectProfile(String profileId) async {
    try {
      final profile = _profiles.firstWhere((p) => p.id == profileId);
      _currentProfile = profile;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentProfileIdKey, profileId);

      await updateProfileLastUsed(profileId);

      await GamificationService().loadProgressForProfile(profileId);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao selecionar perfil: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentProfileIdKey);
    notifyListeners();
  }

  Future<bool> updateProfile(String profileId, {String? name, String? avatarEmoji}) async {
    try {
      final index = _profiles.indexWhere((p) => p.id == profileId);
      if (index >= 0) {
        _profiles[index] = _profiles[index].copyWith(
          name: name,
          avatarEmoji: avatarEmoji,
        );

        if (_currentProfile?.id == profileId) {
          _currentProfile = _profiles[index];
        }

        await _saveProfiles();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao atualizar perfil: $e');
      return false;
    }
  }

  Future<void> updateProfileLastUsed(String profileId) async {
    try {
      final index = _profiles.indexWhere((p) => p.id == profileId);
      if (index >= 0) {
        _profiles[index] = _profiles[index].copyWith(
          lastUsed: DateTime.now(),
        );
        await _saveProfiles();
      }
    } catch (e) {
      debugPrint('Erro ao atualizar lastUsed: $e');
    }
  }

  Future<void> _saveProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _profiles.map((p) => p.toJson()).toList();
      await prefs.setString(_profilesKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Erro ao salvar perfis: $e');
    }
  }

  // ✅ MÉTODO ADICIONADO NO FINAL
  Future<void> deleteProfile(String id) async {
    await loadProfiles();
    _profiles.removeWhere((p) => p.id == id);

    final prefs = await SharedPreferences.getInstance();
    final profilesJson = _profiles.map((p) => json.encode(p.toJson())).toList();
    await prefs.setStringList('profiles', profilesJson);
  }
}