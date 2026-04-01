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
  final String? assetPath;

  Pictogram({
    required this.id,
    required this.label,
    required this.icon,
    this.assetPath,
  });
}

final List<PictogramCategory> defaultPictogramCategories = [
  PictogramCategory(
    id: 'needs',
    name: 'Necessidades',
    icon: Icons.local_drink,
    color: const Color(0xFF4A90E2),
    pictograms: [
      Pictogram(id: 'water', label: 'Água', icon: Icons.local_drink, assetPath: 'assets/images/pictograms/necessidades/water.png'),
      Pictogram(id: 'food', label: 'Comida', icon: Icons.restaurant, assetPath: 'assets/images/pictograms/necessidades/food.png'),
      Pictogram(id: 'bathroom', label: 'Banheiro', icon: Icons.wc, assetPath: 'assets/images/pictograms/necessidades/bathroom.png'),
      Pictogram(id: 'rest', label: 'Descansar', icon: Icons.hotel, assetPath: 'assets/images/pictograms/necessidades/rest.png'),
      Pictogram(id: 'help', label: 'Ajuda', icon: Icons.help, assetPath: 'assets/images/pictograms/necessidades/help.png'),
      Pictogram(id: 'medicine', label: 'Remédio', icon: Icons.medical_services, assetPath: 'assets/images/pictograms/necessidades/medicine.png'),
    ],
  ),
  PictogramCategory(
    id: 'emotions',
    name: 'Sentimentos',
    icon: Icons.emoji_emotions,
    color: const Color(0xFFE74C3C),
    pictograms: [
      Pictogram(id: 'happy', label: 'Feliz', icon: Icons.sentiment_very_satisfied, assetPath: 'assets/images/pictograms/sentimentos/feliz.png'),
      Pictogram(id: 'sad', label: 'Triste', icon: Icons.sentiment_very_dissatisfied, assetPath: 'assets/images/pictograms/sentimentos/triste.png'),
      Pictogram(id: 'angry', label: 'Bravo', icon: Icons.mood_bad, assetPath: 'assets/images/pictograms/sentimentos/bravo.png'),
      Pictogram(id: 'tired', label: 'Cansado', icon: Icons.sentiment_satisfied, assetPath: 'assets/images/pictograms/sentimentos/cansado.png'),
      Pictogram(id: 'scared', label: 'Assustado', icon: Icons.sentiment_very_dissatisfied, assetPath: 'assets/images/pictograms/sentimentos/assustado.png'),
      Pictogram(id: 'excited', label: 'Empolgado', icon: Icons.sentiment_very_satisfied, assetPath: 'assets/images/pictograms/sentimentos/empolgado.png'),
    ],
  ),
  PictogramCategory(
    id: 'actions',
    name: 'Ações',
    icon: Icons.directions_run,
    color: const Color(0xFF27AE60),
    pictograms: [
      Pictogram(id: 'play', label: 'Brincar', icon: Icons.sports_soccer, assetPath: 'assets/images/pictograms/acoes/play.png'),
      Pictogram(id: 'eat', label: 'Comer', icon: Icons.restaurant, assetPath: 'assets/images/pictograms/acoes/eat.png'),
      Pictogram(id: 'sleep', label: 'Dormir', icon: Icons.hotel, assetPath: 'assets/images/pictograms/acoes/sleep.png'),
      Pictogram(id: 'study', label: 'Estudar', icon: Icons.school, assetPath: 'assets/images/pictograms/acoes/study.png'),
      Pictogram(id: 'watch', label: 'Assistir', icon: Icons.tv, assetPath: 'assets/images/pictograms/acoes/watch.png'),
      Pictogram(id: 'walk', label: 'Caminhar', icon: Icons.directions_walk, assetPath: 'assets/images/pictograms/acoes/walk.png'),
    ],
  ),
  PictogramCategory(
    id: 'people',
    name: 'Pessoas',
    icon: Icons.people,
    color: const Color(0xFF9B59B6),
    pictograms: [
      Pictogram(id: 'mom', label: 'Mamãe', icon: Icons.woman, assetPath: 'assets/images/pictograms/pessoas/mamãe.png'),
      Pictogram(id: 'dad', label: 'Papai', icon: Icons.man, assetPath: 'assets/images/pictograms/pessoas/papai.png'),
      Pictogram(id: 'friend', label: 'Amigo', icon: Icons.person, assetPath: 'assets/images/pictograms/pessoas/amigo.png'),
      Pictogram(id: 'teacher', label: 'Professor', icon: Icons.school, assetPath: 'assets/images/pictograms/pessoas/professor.png'),
      Pictogram(id: 'sibling', label: 'Irmão', icon: Icons.people, assetPath: 'assets/images/pictograms/pessoas/irmão.png'),
    ],
  ),
  PictogramCategory(
    id: 'places',
    name: 'Lugares',
    icon: Icons.location_on,
    color: const Color(0xFFF39C12),
    pictograms: [
      Pictogram(id: 'home', label: 'Casa', icon: Icons.home, assetPath: 'assets/images/pictograms/lugares/home.png'),
      Pictogram(id: 'school', label: 'Escola', icon: Icons.school, assetPath: 'assets/images/pictograms/lugares/school.png'),
      Pictogram(id: 'park', label: 'Parque', icon: Icons.park, assetPath: 'assets/images/pictograms/lugares/park.png'),
      Pictogram(id: 'hospital', label: 'Hospital', icon: Icons.local_hospital, assetPath: 'assets/images/pictograms/lugares/hospital.png'),
      Pictogram(id: 'store', label: 'Loja', icon: Icons.shopping_cart, assetPath: 'assets/images/pictograms/lugares/store.png'),
      Pictogram(id: 'playground', label: 'Playground', icon: Icons.sports_soccer, assetPath: 'assets/images/pictograms/lugares/playground.png'),
    ],
  ),
  PictogramCategory(
    id: 'objects',
    name: 'Objetos',
    icon: Icons.category,
    color: const Color(0xFF1ABC9C),
    pictograms: [
      Pictogram(id: 'toy', label: 'Brinquedo', icon: Icons.toys, assetPath: 'assets/images/pictograms/objetos/toy.png'),
      Pictogram(id: 'book', label: 'Livro', icon: Icons.book, assetPath: 'assets/images/pictograms/objetos/book.png'),
      Pictogram(id: 'music', label: 'Música', icon: Icons.music_note, assetPath: 'assets/images/pictograms/objetos/music.png'),
      Pictogram(id: 'phone', label: 'Telefone', icon: Icons.phone, assetPath: 'assets/images/pictograms/objetos/phone.png'),
      Pictogram(id: 'tablet', label: 'Tablet', icon: Icons.tablet, assetPath: 'assets/images/pictograms/objetos/tablet.png'),
      Pictogram(id: 'ball', label: 'Bola', icon: Icons.sports_soccer, assetPath: 'assets/images/pictograms/objetos/ball.png'),
    ],
  ),
];