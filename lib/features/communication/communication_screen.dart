import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/pictogram_model.dart';
import '../../widgets/pictogram_card.dart';
import '../../widgets/category_tab.dart';
import '../../services/gamification_service.dart';
import '../../models/achievement_model.dart';
import '../../widgets/voice_confirmation_dialog.dart';
import '../../services/auth_service.dart';

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
    _loadCurrentChild();
    _gamificationService.addAchievementListener(_onAchievementUnlocked);
  }

  Future<void> _loadCurrentChild() async {
    final prefs = await SharedPreferences.getInstance();
    String? childId = prefs.getString('currentChildId');
    if (childId == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) childId = user.uid;
    }
    if (childId != null) {
      _gamificationService.setCurrentChild(childId);
      await _gamificationService.initializeForProfile(childId);
    }
  }

  void _onAchievementUnlocked(Achievement achievement) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🏆 Conquista: ${achievement.title}')));
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5);
  }

  void _adicionarPictograma(Pictogram pictogram) async {
    final bool? success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceConfirmationDialog(pictogram: pictogram),
    );

    if (success == true) {
      setState(() => _fraseAtual.add(pictogram));
      
      // 🔥 AGORA REGISTRA CATEGORIA E PONTUA MESMO COM 1 PALAVRA
      final category = _getCategoryForPictogram(pictogram);
      if (category != null) {
        await _gamificationService.registerCategoryUsage(category);
      }
      await _gamificationService.addStar();
    }
  }

  String? _getCategoryForPictogram(Pictogram pictogram) {
    for (var category in defaultPictogramCategories) {
      if (category.pictograms.any((p) => p.label == pictogram.label)) return category.name;
    }
    return null;
  }

  Future<void> _falarFrase() async {
    if (_fraseAtual.isNotEmpty) {
      String fraseCompleta = _fraseAtual.map((p) => p.label).join(' ');
      await _flutterTts.speak(fraseCompleta);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunicação'),
        actions: [
          ListenableBuilder(
            listenable: _gamificationService,
            builder: (context, _) => Center(child: Text('⭐ ${_gamificationService.progress.totalStars}  ')),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (mounted) Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _fraseAtual.map((p) => Chip(label: Text(p.label))).toList(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(onPressed: _falarFrase, icon: const Icon(Icons.volume_up), label: const Text('Falar')),
                    IconButton(onPressed: () => setState(() => _fraseAtual.clear()), icon: const Icon(Icons.clear_all)),
                  ],
                ),
              ],
            ),
          ),
          // Categorias e Grid permanecem iguais...
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
              itemCount: defaultPictogramCategories[_selectedCategoryIndex].pictograms.length,
              itemBuilder: (context, index) {
                final p = defaultPictogramCategories[_selectedCategoryIndex].pictograms[index];
                return PictogramCard(
                  pictogram: p,
                  categoryColor: defaultPictogramCategories[_selectedCategoryIndex].color,
                  onTap: () => _adicionarPictograma(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
