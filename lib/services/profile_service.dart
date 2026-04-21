import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/profiles/models/profile_model.dart';
import '../models/child_profile.dart';
import '../models/profile_settings_model.dart';
import '../models/user_progress_model.dart';
import 'gamification_service.dart';
import 'database_service.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  static const String _profilesKey = 'user_profiles';
  static const String _currentProfileIdKey = 'current_profile_id';

  List<UserProfile> _profiles = [];
  UserProfile? _currentProfile;

  List<UserProfile> get profiles => List.unmodifiable(_profiles);
  UserProfile? get currentProfile => _currentProfile;

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
        _profiles = jsonList.map((json) => UserProfile.fromJson(json)).toList();
      }
      notifyListeners();
    } catch (e) {
      _profiles = [];
    }
  }

  Future<void> loadCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? profileId = prefs.getString(_currentProfileIdKey);
    if (profileId != null) {
      try {
        _currentProfile = _profiles.firstWhere((p) => p.id == profileId);
        GamificationService().setCurrentChild(_currentProfile?.childId ?? profileId);
      } catch (e) {
        _currentProfile = null;
      }
    }
    notifyListeners();
  }

  Future<bool> createProfile(String name, String avatarEmoji) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final childId = 'child_${DateTime.now().millisecondsSinceEpoch}';

      final newProfile = UserProfile(
        id: childId,
        name: name,
        avatarEmoji: avatarEmoji,
        createdAt: DateTime.now(),
        childId: childId,
      );

      _profiles.add(newProfile);
      await _saveProfiles();

      if (user != null) {
        final newChild = ChildProfile(
          id: childId,
          name: name,
          professionalIds: [user.uid, user.email ?? ''],
          settings: ProfileSettings(voiceRate: 0.5, voicePitch: 1.0, highContrast: false, selectedVoice: 'pt-BR'),
          progress: UserProgress(userId: childId),
          lastActive: DateTime.now(),
          createdAt: DateTime.now(),
        );
        await DatabaseService().syncChildToCloud(newChild);
      }

      GamificationService().setCurrentChild(childId);
      await GamificationService().initializeForProfile(childId);

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> selectProfile(String profileId) async {
    try {
      final profile = _profiles.firstWhere((p) => p.id == profileId);
      _currentProfile = profile;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentProfileIdKey, profileId);

      final cloudId = profile.childId ?? profile.id;
      GamificationService().setCurrentChild(cloudId);
      await GamificationService().initializeForProfile(profileId);

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilesKey, jsonEncode(_profiles.map((p) => p.toJson()).toList()));
  }

  Future<void> logout() async {
    _currentProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentProfileIdKey);
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    await _saveProfiles();
    notifyListeners();
  }

  Future<bool> updateProfile(String profileId, {String? name, String? avatarEmoji}) async {
    final index = _profiles.indexWhere((p) => p.id == profileId);
    if (index >= 0) {
      _profiles[index] = _profiles[index].copyWith(name: name, avatarEmoji: avatarEmoji);
      await _saveProfiles();
      notifyListeners();
      return true;
    }
    return false;
  }
}