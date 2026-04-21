import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final String name;
  final String avatarEmoji;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final String? childId; // ✅ ADICIONADO

  UserProfile({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.createdAt,
    this.lastUsed,
    this.childId, // ✅ ADICIONADO
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarEmoji': avatarEmoji,
    'createdAt': createdAt.toIso8601String(),
    'lastUsed': lastUsed?.toIso8601String(),
    'childId': childId, // ✅ ADICIONADO
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      avatarEmoji: json['avatarEmoji'],
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
      childId: json['childId'], // ✅ ADICIONADO
    );
  }

  UserProfile copyWith({
    String? name,
    String? avatarEmoji,
    DateTime? lastUsed,
    String? childId,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      createdAt: createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      childId: childId ?? this.childId,
    );
  }
}

const List<String> availableAvatars = ['😊','🦁','🐶','🐱','🐼','🐸','🐧','🦊','🐨','🦉','🐙','🦄','🌈','⭐','🚀','⚽'];