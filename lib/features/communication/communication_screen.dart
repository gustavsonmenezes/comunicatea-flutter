// features/communication/communication_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/pictogram_model.dart';
import '../../widgets/pictogram_card.dart';
import '../../widgets/category_tab.dart';
import '../../services/gamification_service.dart';
import '../../models/achievement_model.dart';
import '../../models/user_progress_model.dart';
import '../../widgets/voice_confirmation_dialog.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final List<Pictogram> _fraseAtual = [];
  final FlutterTts _flutterTts = FlutterTts();
  int _selectedCategoryIndex = 0;

  final GamificationService _gamificationService = GamificationService();

  @override
  void initState() {
    super.initState();
    _initTts();
    _gamificationService.addAchievementListener(_onAchievementUnlocked);
  }

  void _onAchievementUnlocked(Achievement achievement) {
    _showAchievementNotification(achievement);
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5);
  }

  void _adicionarPictograma(Pictogram pictogram) async {
    // Exibe o diálogo de reconhecimento de voz
    final bool? success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceConfirmationDialog(pictogram: pictogram),
    );

    // Se a criança falou a palavra corretamente, adiciona à frase
    if (success == true) {
      setState(() {
        _fraseAtual.add(pictogram);
      });
    }
  }

  void _removerUltimoPictograma() {
    if (_fraseAtual.isNotEmpty) {
      setState(() {
        _fraseAtual.removeLast();
      });
    }
  }

  void _limparFrase() {
    setState(() {
      _fraseAtual.clear();
    });
  }

  void _removerPictogramaNoIndice(int index) {
    setState(() {
      _fraseAtual.removeAt(index);
    });
  }

  Future<void> _falarFrase() async {
    if (_fraseAtual.isNotEmpty) {
      String fraseCompleta = _fraseAtual.map((p) => p.label).join(' ');
      await _flutterTts.speak(fraseCompleta);

      // SÓ ganha estrela se tiver 2 ou mais palavras
      if (_fraseAtual.length >= 2) {
        await _gamificationService.addStar();

        // Registrar categorias usadas
        for (var pictogram in _fraseAtual) {
          final category = _getCategoryForPictogram(pictogram.id);
          if (category != null) {
            await _gamificationService.registerCategoryUsage(category);
          }
        }
      }
    }
  }

  String? _getCategoryForPictogram(String pictogramId) {
    for (var category in defaultPictogramCategories) {
      if (category.pictograms.any((p) => p.id == pictogramId)) {
        return category.id;
      }
    }
    return null;
  }

  void _showAchievementNotification(Achievement achievement) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(achievement.icon, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🏆 Nova Conquista!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    achievement.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: achievement.color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunicação'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Mostrar estrelas
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                ListenableBuilder(
                  listenable: _gamificationService,
                  builder: (context, child) {
                    return Text(
                      '${_gamificationService.progress.totalStars}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de frase atual
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_fraseAtual.length, (index) {
                      final pictogram = _fraseAtual[index];
                      return GestureDetector(
                        onTap: () => _removerPictogramaNoIndice(index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: pictogram.assetPath != null
                                        ? Image.asset(
                                      pictogram.assetPath!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(pictogram.icon, size: 20),
                                    )
                                        : Icon(pictogram.icon, size: 20),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(pictogram.label),
                                ],
                              ),
                              Positioned(
                                top: -12,
                                right: -12,
                                child: Icon(
                                  Icons.remove_circle,
                                  color: Colors.red.withOpacity(0.7),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _falarFrase,
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Falar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _removerUltimoPictograma,
                      icon: const Icon(Icons.backspace),
                      color: Colors.red,
                    ),
                    IconButton(
                      onPressed: _limparFrase,
                      icon: const Icon(Icons.clear_all),
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Abas de categorias
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: defaultPictogramCategories.length,
              itemBuilder: (context, index) {
                return CategoryTab(
                  category: defaultPictogramCategories[index],
                  isSelected: index == _selectedCategoryIndex,
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                );
              },
            ),
          ),

          // Grid de pictogramas da categoria selecionada
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: defaultPictogramCategories[_selectedCategoryIndex].pictograms.length,
              itemBuilder: (context, index) {
                final pictogram = defaultPictogramCategories[_selectedCategoryIndex].pictograms[index];
                return PictogramCard(
                  pictogram: pictogram,
                  categoryColor: defaultPictogramCategories[_selectedCategoryIndex].color,
                  onTap: () => _adicionarPictograma(pictogram),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gamificationService.removeAchievementListener(_onAchievementUnlocked);
    _flutterTts.stop();
    super.dispose();
  }
}