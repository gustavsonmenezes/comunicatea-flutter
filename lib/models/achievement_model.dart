// models/achievement_model.dart
import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int requiredStars;
  final Color color;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredStars,
    required this.color,
  });
}

final List<Achievement> appAchievements = [
  Achievement(
    id: 'first_steps',
    title: 'Primeiros Passos',
    description: 'Acumulou 5 estrelas',
    icon: Icons.stars,
    requiredStars: 5,
    color: const Color(0xFF4A90E2),
  ),
  Achievement(
    id: 'communicator',
    title: 'Comunicador',
    description: 'Acumulou 20 estrelas',
    icon: Icons.chat,
    requiredStars: 20,
    color: const Color(0xFF27AE60),
  ),
  Achievement(
    id: 'explorer',
    title: 'Explorador',
    description: 'Acumulou 50 estrelas',
    icon: Icons.explore,
    requiredStars: 50,
    color: const Color(0xFFE74C3C),
  ),
  Achievement(
    id: 'master',
    title: 'Mestre da Comunicação',
    description: 'Acumulou 100 estrelas',
    icon: Icons.emoji_events,
    requiredStars: 100,
    color: const Color(0xFFF39C12),
  ),
  Achievement(
    id: 'dedicated',
    title: 'Dedicado',
    description: 'Usou todas as categorias',
    icon: Icons.category,
    requiredStars: 0,
    color: const Color(0xFF9B59B6),
  ),
];
