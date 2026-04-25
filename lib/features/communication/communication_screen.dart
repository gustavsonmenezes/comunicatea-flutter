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
  final GamificationService _gamificationService = GamificationService();
  
  int? _selectedCategoryIndex; 

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadCurrentChild();
    _gamificationService.addAchievementListener(_onAchievementUnlocked);
  }

  Future<void> _loadCurrentChild() async {
    final prefs = await SharedPreferences.getInstance();
    String? childId = prefs.getString('currentChildId') ?? FirebaseAuth.instance.currentUser?.uid;
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
      final category = _getCategoryName(pictogram);
      if (category != null) await _gamificationService.registerCategoryUsage(category);
      await _gamificationService.addStar();
    }
  }

  String? _getCategoryName(Pictogram pictogram) {
    for (var cat in defaultPictogramCategories) {
      if (cat.pictograms.any((p) => p.id == pictogram.id)) return cat.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Minha Prancha'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          ListenableBuilder(
            listenable: _gamificationService,
            builder: (context, _) => Center(child: Text('⭐ ${_gamificationService.progress.totalStars}  ', style: const TextStyle(fontWeight: FontWeight.bold))),
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
          _buildSentenceArea(),
          Expanded(
            child: _selectedCategoryIndex == null 
                ? _buildCategoryMenu() 
                : _buildPictogramGrid(), 
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue[50],
      child: Column(
        children: [
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!, width: 2),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              children: _fraseAtual.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InputChip( // 🔥 Trocado ActionChip por InputChip
                  avatar: p.assetPath != null ? Image.asset(p.assetPath!) : Icon(p.icon, size: 20),
                  label: Text(p.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onDeleted: () => setState(() => _fraseAtual.remove(p)),
                  deleteIconColor: Colors.red,
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _flutterTts.speak(_fraseAtual.map((p) => p.label).join(' ')),
                icon: const Icon(Icons.volume_up, size: 28),
                label: const Text('FALAR FRASE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
              IconButton(
                onPressed: () => setState(() => _fraseAtual.clear()),
                icon: const Icon(Icons.delete_forever, color: Colors.red, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryMenu() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.1,
      ),
      itemCount: defaultPictogramCategories.length,
      itemBuilder: (context, index) {
        final cat = defaultPictogramCategories[index];
        return InkWell(
          onTap: () => setState(() => _selectedCategoryIndex = index),
          child: Container(
            decoration: BoxDecoration(
              color: cat.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cat.color, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat.icon, size: 50, color: cat.color),
                const SizedBox(height: 12),
                Text(cat.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cat.color)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPictogramGrid() {
    final category = defaultPictogramCategories[_selectedCategoryIndex!];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: category.color.withOpacity(0.2),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedCategoryIndex = null),
                icon: const Icon(Icons.arrow_back),
                label: const Text('VOLTAR', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: category.color, foregroundColor: Colors.white),
              ),
              const Spacer(),
              Text(category.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: category.color)),
              const SizedBox(width: 8),
              Icon(category.icon, color: category.color),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: category.pictograms.length,
            itemBuilder: (context, index) {
              final p = category.pictograms[index];
              return PictogramCard(
                pictogram: p,
                categoryColor: category.color,
                onTap: () => _adicionarPictograma(p),
              );
            },
          ),
        ),
      ],
    );
  }
}
