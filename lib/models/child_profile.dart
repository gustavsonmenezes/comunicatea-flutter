import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_settings_model.dart';
import 'user_progress_model.dart';

class ChildProfile {
  final String id;
  final String shortId; // 🔥 Novo campo para vínculo fácil
  final String name;
  final String email;
  final int age;
  final String diagnosis;
  final String photoUrl;
  final List<String> professionalIds;
  final List<String>? professionalEmails;
  final ProfileSettings settings;
  final UserProgress progress;
  final DateTime? lastActive;
  final DateTime? createdAt;

  ChildProfile({
    required this.id,
    this.shortId = '', // 🔥 Novo campo
    required this.name,
    this.email = '',
    required this.age,
    this.diagnosis = '',
    this.photoUrl = '',
    this.professionalIds = const [],
    this.professionalEmails = const [],
    required this.settings,
    required this.progress,
    this.lastActive,
    this.createdAt,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] ?? '',
      shortId: json['shortId'] ?? '', // 🔥 Novo campo
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] ?? 0,
      diagnosis: json['diagnosis'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      professionalIds: json['professionalIds'] != null
          ? List<String>.from(json['professionalIds'])
          : [],
      professionalEmails: json['professionalEmails'] != null
          ? List<String>.from(json['professionalEmails'])
          : [],
      settings: ProfileSettings.fromJson(json['settings'] ?? {}),
      progress: UserProgress.fromJson(json['progress'] ?? {}),
      lastActive: json['lastActive'] != null
          ? (json['lastActive'] is Timestamp
          ? (json['lastActive'] as Timestamp).toDate()
          : DateTime.tryParse(json['lastActive'].toString()))
          : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shortId': shortId, // 🔥 Novo campo
      'name': name,
      'email': email,
      'age': age,
      'diagnosis': diagnosis,
      'photoUrl': photoUrl,
      'professionalIds': professionalIds,
      'professionalEmails': professionalEmails,
      'settings': settings.toJson(),
      'progress': progress.toJson(),
      'lastActive': lastActive?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Método auxiliar para criar uma cópia com campos alterados
  ChildProfile copyWith({
    String? name,
    String? email, // 🔥 NOVO CAMPO
    int? age,
    String? diagnosis,
    String? photoUrl,
    ProfileSettings? settings,
    UserProgress? progress,
    DateTime? lastActive,
    DateTime? createdAt,
  }) {
    return ChildProfile(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email, // 🔥 NOVO CAMPO
      age: age ?? this.age,
      diagnosis: diagnosis ?? this.diagnosis,
      photoUrl: photoUrl ?? this.photoUrl,
      professionalIds: this.professionalIds,
      professionalEmails: this.professionalEmails,
      settings: settings ?? this.settings,
      progress: progress ?? this.progress,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
