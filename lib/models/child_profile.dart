import 'profile_settings_model.dart';
import 'user_progress_model.dart';

class ChildProfile {
  final String id;
  final String name;
  final int? age;
  final String? diagnosis;
  final String? photoUrl;
  final String? responsibleId;
  final List<String> professionalIds;
  final ProfileSettings settings;
  final UserProgress progress;
  final DateTime lastActive;
  final DateTime createdAt;

  ChildProfile({
    required this.id,
    required this.name,
    this.age,
    this.diagnosis,
    this.photoUrl,
    this.responsibleId,
    this.professionalIds = const [],
    required this.settings,
    required this.progress,
    required this.lastActive,
    required this.createdAt,
  });

  // Estatísticas calculadas
  int get totalSessions => progress.totalSessions;
  int get totalPhrases => progress.totalPhrasesBuilt;
  int get activeDays => progress.activeDays.length;

  Map<String, int> get mostUsedPictograms {
    final sorted = progress.pictogramUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      diagnosis: json['diagnosis'],
      photoUrl: json['photoUrl'],
      responsibleId: json['responsibleId'],
      professionalIds: json['professionalIds'] != null
          ? List<String>.from(json['professionalIds'])
          : [],
      settings: ProfileSettings.fromJson(json['settings'] ?? {}),
      progress: UserProgress.fromJson(json['progress'] ?? {}),
      lastActive: DateTime.parse(json['lastActive'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'diagnosis': diagnosis,
      'photoUrl': photoUrl,
      'responsibleId': responsibleId,
      'professionalIds': professionalIds,
      'settings': settings.toJson(),
      'progress': progress.toJson(),
      'lastActive': lastActive.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}