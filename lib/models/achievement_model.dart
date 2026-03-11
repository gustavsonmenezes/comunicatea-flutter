import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int requiredStars; // Exemplo de critério simples

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.requiredStars = 0,
  });
}

// Lista estática de conquistas do app
final List<Achievement> appAchievements = [
  Achievement(
    id: 'first_word',
    title: 'Primeira Palavra',
    description: 'Você falou sua primeira frase!',
    icon: Icons.star,
    requiredStars: 1,
  ),
  Achievement(
    id: 'talkative',
    title: 'Tagarela',
    description: 'Você já falou 20 frases!',
    icon: Icons.forum,
    requiredStars: 20,
  ),
  Achievement(
    id: 'explorer',
    title: 'Explorador',
    description: 'Usou pictogramas de 3 categorias diferentes.',
    icon: Icons.explore,
  ),
];
