// lib/features/professional/professional_model.dart
import 'package:flutter/material.dart';

class ProfessionalProfile {
  final String id;
  final String name;
  final String avatarEmoji;
  final String croNumber;
  final String specialty;
  final int weeklyGoalStars;
  final int activeChildrenCount;
  final DateTime createdAt;

  ProfessionalProfile({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.croNumber,
    required this.specialty,
    this.weeklyGoalStars = 50,
    this.activeChildrenCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarEmoji': avatarEmoji,
    'croNumber': croNumber,
    'specialty': specialty,
    'weeklyGoalStars': weeklyGoalStars,
    'activeChildrenCount': activeChildrenCount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ProfessionalProfile.fromJson(Map<String, dynamic> json) {
    return ProfessionalProfile(
      id: json['id'],
      name: json['name'],
      avatarEmoji: json['avatarEmoji'],
      croNumber: json['croNumber'],
      specialty: json['specialty'],
      weeklyGoalStars: json['weeklyGoalStars'] ?? 50,
      activeChildrenCount: json['activeChildrenCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
