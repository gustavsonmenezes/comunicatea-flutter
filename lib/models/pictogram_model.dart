import 'package:flutter/material.dart';

class PictogramCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<Pictogram> pictograms;

  PictogramCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.pictograms,
  });
}

class Pictogram {
  final String id;
  final String label;
  final IconData icon;
  final String? imageUrl; // Para imagens reais no futuro

  Pictogram({
    required this.id,
    required this.label,
    required this.icon,
    this.imageUrl,
  });
}

// ✅ RENOMEADO para evitar conflito
final List<PictogramCategory> defaultPictogramCategories = [
  PictogramCategory(
    id: 'needs',
    name: 'Necessidades',
    icon: Icons.local_drink,
    color: const Color(0xFF4A90E2),
    pictograms: [
      Pictogram(id: 'water', label: 'Água', icon: Icons.local_drink),
      Pictogram(id: 'food', label: 'Comida', icon: Icons.restaurant),
      Pictogram(id: 'bathroom', label: 'Banheiro', icon: Icons.wc),
      Pictogram(id: 'rest', label: 'Descansar', icon: Icons.hotel),
      Pictogram(id: 'help', label: 'Ajuda', icon: Icons.help),
      Pictogram(id: 'medicine', label: 'Remédio', icon: Icons.medical_services),
    ],
  ),
  PictogramCategory(
    id: 'emotions',
    name: 'Sentimentos',
    icon: Icons.emoji_emotions,
    color: const Color(0xFFE74C3C),
    pictograms: [
      Pictogram(id: 'happy', label: 'Feliz', icon: Icons.sentiment_very_satisfied),
      Pictogram(id: 'sad', label: 'Triste', icon: Icons.sentiment_very_dissatisfied),
      Pictogram(id: 'angry', label: 'Bravo', icon: Icons.mood_bad),
      Pictogram(id: 'tired', label: 'Cansado', icon: Icons.sentiment_satisfied),
      Pictogram(id: 'scared', label: 'Assustado', icon: Icons.sentiment_very_dissatisfied),
      Pictogram(id: 'excited', label: 'Empolgado', icon: Icons.sentiment_very_satisfied),
    ],
  ),
  PictogramCategory(
    id: 'actions',
    name: 'Ações',
    icon: Icons.directions_run,
    color: const Color(0xFF27AE60),
    pictograms: [
      Pictogram(id: 'play', label: 'Brincar', icon: Icons.sports_soccer),
      Pictogram(id: 'eat', label: 'Comer', icon: Icons.restaurant),
      Pictogram(id: 'sleep', label: 'Dormir', icon: Icons.hotel),
      Pictogram(id: 'study', label: 'Estudar', icon: Icons.school),
      Pictogram(id: 'watch', label: 'Assistir', icon: Icons.tv),
      Pictogram(id: 'walk', label: 'Caminhar', icon: Icons.directions_walk),
    ],
  ),
  PictogramCategory(
    id: 'people',
    name: 'Pessoas',
    icon: Icons.people,
    color: const Color(0xFF9B59B6),
    pictograms: [
      Pictogram(id: 'mom', label: 'Mamãe', icon: Icons.woman),
      Pictogram(id: 'dad', label: 'Papai', icon: Icons.man),
      Pictogram(id: 'friend', label: 'Amigo', icon: Icons.person),
      Pictogram(id: 'teacher', label: 'Professor', icon: Icons.school),
      Pictogram(id: 'doctor', label: 'Médico', icon: Icons.medical_services),
      Pictogram(id: 'sibling', label: 'Irmão', icon: Icons.people),
    ],
  ),
  PictogramCategory(
    id: 'places',
    name: 'Lugares',
    icon: Icons.location_on,
    color: const Color(0xFFF39C12),
    pictograms: [
      Pictogram(id: 'home', label: 'Casa', icon: Icons.home),
      Pictogram(id: 'school', label: 'Escola', icon: Icons.school),
      Pictogram(id: 'park', label: 'Parque', icon: Icons.park),
      Pictogram(id: 'hospital', label: 'Hospital', icon: Icons.local_hospital),
      Pictogram(id: 'store', label: 'Loja', icon: Icons.shopping_cart),
      Pictogram(id: 'playground', label: 'Playground', icon: Icons.sports_soccer),
    ],
  ),
  PictogramCategory(
    id: 'objects',
    name: 'Objetos',
    icon: Icons.category,
    color: const Color(0xFF1ABC9C),
    pictograms: [
      Pictogram(id: 'toy', label: 'Brinquedo', icon: Icons.toys),
      Pictogram(id: 'book', label: 'Livro', icon: Icons.book),
      Pictogram(id: 'phone', label: 'Telefone', icon: Icons.phone),
      Pictogram(id: 'tablet', label: 'Tablet', icon: Icons.tablet),
      Pictogram(id: 'ball', label: 'Bola', icon: Icons.sports_soccer),
      Pictogram(id: 'music', label: 'Música', icon: Icons.music_note),
    ],
  ),
];
