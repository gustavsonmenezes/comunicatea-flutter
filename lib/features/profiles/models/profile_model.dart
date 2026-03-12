// features/profiles/models/profile_model.dart
import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final String name;
  final String avatarEmoji;
  final DateTime createdAt;
  final DateTime? lastUsed;

  UserProfile({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.createdAt,
    this.lastUsed,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarEmoji': avatarEmoji,
    'createdAt': createdAt.toIso8601String(),
    'lastUsed': lastUsed?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      avatarEmoji: json['avatarEmoji'],
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'])
          : null,
    );
  }

  UserProfile copyWith({
    String? name,
    String? avatarEmoji,
    DateTime? lastUsed,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      createdAt: createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}

// Lista de avatares disponíveis
const List<String> availableAvatars = [
  '😊', // Rosto feliz
  '🦁', // Leão
  '🐶', // Cachorro
  '🐱', // Gato
  '🐼', // Panda
  '🐸', // Sapo
  '🐧', // Pinguim
  '🦊', // Raposa
  '🐨', // Coala
  '🦉', // Coruja
  '🐙', // Polvo
  '🦄', // Unicórnio
  '🌈', // Arco-íris
  '⭐', // Estrela
  '🚀', // Foguete
  '⚽', // Bola
];