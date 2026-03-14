// lib/features/memory_game/screens/memory_game_screen.dart
import 'package:flutter/material.dart';
import '../models/memory_card_model.dart';
import '../models/pictogram_adapter.dart';
import '../services/memory_game_service.dart';
import '../../../services/sound_manager.dart';
import '../../../services/gamification_service.dart';
import '../../../services/profile_service.dart';
import '../../../theme/app_theme.dart';

class MemoryGameScreen extends StatefulWidget {
  final String category;
  final List<MemoryPictogram> pictograms;

  const MemoryGameScreen({
    super.key,
    required this.category,
    required this.pictograms,
  });

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late List<MemoryCardModel> _cards;
  final List<MemoryCardModel> _selectedCards = [];
  final MemoryGameService _gameService = MemoryGameService();
  final SoundManager _soundManager = SoundManager();
  final GamificationService _gamificationService = GamificationService();
  final ProfileService _profileService = ProfileService();

  int _matches = 0;
  int _errors = 0; // ← MUDAMOS DE _attempts PARA _errors
  bool _isGameLocked = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _cards = _gameService.createGameCards(widget.pictograms);
    _matches = 0;
    _errors = 0; // ← MUDAMOS AQUI
    _selectedCards.clear();
  }

  Future<void> _onCardTap(MemoryCardModel card) async {
    if (_isGameLocked || card.isMatched || card.isFlipped) return;

    setState(() {
      card.isFlipped = true;
      _selectedCards.add(card);
    });

    // SOM DESABILITADO TEMPORARIAMENTE
    if (card.soundPath.isNotEmpty) {
      try {
        // await _soundManager.play(card.soundPath);  // ← COMENTADO
      } catch (e) {
        debugPrint('Erro ao tocar som: $e');
      }
    }

    if (_selectedCards.length == 2) {
      _isGameLocked = true;
      // ❌ REMOVEMOS O _errors++ DAQUI

      Future.delayed(const Duration(milliseconds: 600), () {
        _checkMatch();
      });
    }
  }

  void _checkMatch() {
    setState(() {
      final card1 = _selectedCards[0];
      final card2 = _selectedCards[1];

      if (card1.pictogramId == card2.pictogramId) {
        // ✅ ACERTOU - não conta erro
        card1.isMatched = true;
        card2.isMatched = true;
        _matches++;

        if (_matches == _cards.length ~/ 2) {
          _gameCompleted();
        }
      } else {
        // ❌ ERROU - SÓ CONTA AQUI
        _errors++; // ← MOVEMOS O CONTADOR PARA CÁ
        card1.isFlipped = false;
        card2.isFlipped = false;
      }

      _selectedCards.clear();
      _isGameLocked = false;
    });
  }

  Future<void> _gameCompleted() async {
    final currentProfile = _profileService.currentProfile;
    if (currentProfile != null) {
      // GAMIFICAÇÃO DESABILITADA TEMPORARIAMENTE
      try {
        // await _gamificationService.addProgress(  // ← COMENTADO
        //   currentProfile.id,
        //   'memory_game_completed',
        // );
      } catch (e) {
        debugPrint('Erro ao adicionar progresso: $e');
      }
    }

    if (!mounted) return;

    // Calcula pontuação (opcional)
    int totalPairs = _cards.length ~/ 2;
    int score = (totalPairs * 10) - (_errors * 2);
    if (score < 0) score = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Parabéns! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Você completou o jogo!'),
            const SizedBox(height: 8),
            Text('Erros: $_errors'),
            Text('Pontuação: $score'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _initializeGame();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Jogar Novamente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jogo da Memória - ${widget.category}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 20, color: Colors.red), // ← MUDAMOS O ÍCONE
                const SizedBox(width: 4),
                Text(
                  '$_errors', // ← AGORA MOSTRA SÓ OS ERROS
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red, // ← MUDAMOS A COR
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryLight, AppTheme.backgroundColor],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: LinearProgressIndicator(
                value: _cards.isEmpty ? 0 : _matches / (_cards.length ~/ 2),
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return _buildCard(card);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(MemoryCardModel card) {
    // Encontra o pictograma correspondente
    final pictogram = widget.pictograms.firstWhere(
          (p) => p.id == card.pictogramId,
      orElse: () => MemoryPictogram(
        id: '',
        name: '',
        imagePath: '',
        category: '',
      ),
    );

    return GestureDetector(
      onTap: () => _onCardTap(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.isMatched
              ? Colors.green[100]
              : card.isFlipped
              ? Colors.white
              : AppTheme.primaryColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: card.isMatched
                ? Colors.green
                : card.isFlipped
                ? AppTheme.primaryColor
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: card.isMatched
            ? const Icon(Icons.check_circle, color: Colors.green, size: 40)
            : card.isFlipped
            ? _buildCardContent(pictogram)
            : const Center(
          child: Icon(Icons.help_outline, size: 40, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCardContent(MemoryPictogram pictogram) {
    // Se tiver caminho de imagem, tenta carregar
    if (pictogram.imagePath.isNotEmpty && pictogram.imagePath != 'icon') {
      return Image.asset(
        pictogram.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Erro ao carregar imagem: ${pictogram.imagePath}');
          return _buildIconForId(pictogram.id);
        },
      );
    } else {
      return _buildIconForId(pictogram.id);
    }
  }

  Widget _buildIconForId(String id) {
    switch (id) {
    // Necessidades
      case 'water':
        return const Icon(Icons.local_drink, size: 40, color: Color(0xFF4A90E2));
      case 'food':
        return const Icon(Icons.restaurant, size: 40, color: Color(0xFF4A90E2));
      case 'bathroom':
        return const Icon(Icons.wc, size: 40, color: Color(0xFF4A90E2));
      case 'rest':
        return const Icon(Icons.hotel, size: 40, color: Color(0xFF4A90E2));
      case 'help':
        return const Icon(Icons.help, size: 40, color: Color(0xFF4A90E2));
      case 'medicine':
        return const Icon(Icons.medical_services, size: 40, color: Color(0xFF4A90E2));

    // Sentimentos
      case 'happy':
        return const Icon(Icons.sentiment_very_satisfied, size: 40, color: Color(0xFFE74C3C));
      case 'sad':
        return const Icon(Icons.sentiment_very_dissatisfied, size: 40, color: Color(0xFFE74C3C));
      case 'angry':
        return const Icon(Icons.mood_bad, size: 40, color: Color(0xFFE74C3C));
      case 'tired':
        return const Icon(Icons.sentiment_satisfied, size: 40, color: Color(0xFFE74C3C));
      case 'scared':
        return const Icon(Icons.sentiment_very_dissatisfied, size: 40, color: Color(0xFFE74C3C));
      case 'excited':
        return const Icon(Icons.sentiment_very_satisfied, size: 40, color: Color(0xFFE74C3C));

    // Ações
      case 'play':
        return const Icon(Icons.sports_soccer, size: 40, color: Color(0xFF27AE60));
      case 'eat':
        return const Icon(Icons.restaurant, size: 40, color: Color(0xFF27AE60));
      case 'sleep':
        return const Icon(Icons.hotel, size: 40, color: Color(0xFF27AE60));
      case 'study':
        return const Icon(Icons.school, size: 40, color: Color(0xFF27AE60));
      case 'watch':
        return const Icon(Icons.tv, size: 40, color: Color(0xFF27AE60));
      case 'walk':
        return const Icon(Icons.directions_walk, size: 40, color: Color(0xFF27AE60));

    // Pessoas
      case 'mom':
        return const Icon(Icons.woman, size: 40, color: Color(0xFF9B59B6));
      case 'dad':
        return const Icon(Icons.man, size: 40, color: Color(0xFF9B59B6));
      case 'friend':
        return const Icon(Icons.person, size: 40, color: Color(0xFF9B59B6));
      case 'teacher':
        return const Icon(Icons.school, size: 40, color: Color(0xFF9B59B6));
      case 'doctor':
        return const Icon(Icons.medical_services, size: 40, color: Color(0xFF9B59B6));
      case 'sibling':
        return const Icon(Icons.people, size: 40, color: Color(0xFF9B59B6));

    // Lugares
      case 'home':
        return const Icon(Icons.home, size: 40, color: Color(0xFFF39C12));
      case 'school':
        return const Icon(Icons.school, size: 40, color: Color(0xFFF39C12));
      case 'park':
        return const Icon(Icons.park, size: 40, color: Color(0xFFF39C12));
      case 'hospital':
        return const Icon(Icons.local_hospital, size: 40, color: Color(0xFFF39C12));
      case 'store':
        return const Icon(Icons.shopping_cart, size: 40, color: Color(0xFFF39C12));
      case 'playground':
        return const Icon(Icons.sports_soccer, size: 40, color: Color(0xFFF39C12));

    // Objetos
      case 'toy':
        return const Icon(Icons.toys, size: 40, color: Color(0xFF1ABC9C));
      case 'book':
        return const Icon(Icons.book, size: 40, color: Color(0xFF1ABC9C));
      case 'phone':
        return const Icon(Icons.phone, size: 40, color: Color(0xFF1ABC9C));
      case 'tablet':
        return const Icon(Icons.tablet, size: 40, color: Color(0xFF1ABC9C));
      case 'ball':
        return const Icon(Icons.sports_soccer, size: 40, color: Color(0xFF1ABC9C));
      case 'music':
        return const Icon(Icons.music_note, size: 40, color: Color(0xFF1ABC9C));

    // Default
      default:
        return const Icon(Icons.help, size: 40, color: Colors.grey);
    }
  }
}