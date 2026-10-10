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
import '../../services/communication_log_service.dart';
import '../../models/communication_log_model.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final List<Pictogram> _fraseAtual = [];
  final FlutterTts _flutterTts = FlutterTts();
  final GamificationService _gamificationService = GamificationService();
  final CommunicationLogService _logService = CommunicationLogService();
  
  int? _selectedCategoryIndex; 
  String? _childId;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadCurrentChild();
    _gamificationService.addAchievementListener(_onAchievementUnlocked);
  }

  Future<void> _loadCurrentChild() async {
    final prefs = await SharedPreferences.getInstance();
    _childId = prefs.getString('currentChildId') ?? FirebaseAuth.instance.currentUser?.uid;
    if (_childId != null) {
      _gamificationService.setCurrentChild(_childId!);
      await _gamificationService.initializeForProfile(_childId!);
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
    // 1. PRIMEIRO: Tocar o áudio com o nome do pictograma para a criança escutar
    try {
      await _flutterTts.stop();
      await _flutterTts.setLanguage("pt-BR");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(pictogram.label);
    } catch (e) {
      debugPrint("Erro ao reproduzir áudio do pictograma: $e");
    }

    if (!mounted) return;

    // 2. DEPOIS: Abrir a tela de validação para a criança tentar falar
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

  Future<void> _falarFrase() async {
    if (_fraseAtual.isEmpty) return;
    
    final sentenceText = _fraseAtual.map((p) => p.label).join(' ');
    await _flutterTts.speak(sentenceText);

    // 🔥 SALVANDO LOG PARA O PROFISSIONAL
    if (_childId != null) {
      final log = CommunicationLog(
        childId: _childId!,
        sentence: _fraseAtual.map((p) => p.label).toList(),
      );
      await _logService.saveLog(log);
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('ComunicaTEA'),
        backgroundColor: colorScheme.background,
        elevation: 0,
        centerTitle: false,
        actions: [
          ListenableBuilder(
            listenable: _gamificationService,
            builder: (context, _) => Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text('⭐ ${_gamificationService.progress.totalStars}',
                  style: TextStyle(fontWeight: FontWeight.w900, color: Colors.amber[900], fontFamily: 'Quicksand')
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/speech_stats'),
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: colorScheme.error),
            onPressed: () async {
              await AuthService().logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSentenceArea(colorScheme),
          Expanded(
            child: Row(
              children: [
                if (_selectedCategoryIndex != null) _buildSideCategoryRail(colorScheme),
                Expanded(
                  child: _selectedCategoryIndex == null
                      ? _buildCategoryMenu(colorScheme)
                      : _buildPictogramGrid(colorScheme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideCategoryRail(ColorScheme colorScheme) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(right: BorderSide(color: colorScheme.outline.withOpacity(0.1))),
      ),
      child: ListView.builder(
        itemCount: defaultPictogramCategories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              onPressed: () => setState(() => _selectedCategoryIndex = null),
              padding: const EdgeInsets.symmetric(vertical: 20),
            );
          }
          final catIndex = index - 1;
          final cat = defaultPictogramCategories[catIndex];
          final isSelected = _selectedCategoryIndex == catIndex;

          return InkWell(
            onTap: () => setState(() => _selectedCategoryIndex = catIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? cat.color.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(cat.icon, color: cat.color, size: 30),
                  const SizedBox(height: 4),
                  Text(cat.name,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: cat.color, fontFamily: 'Quicksand'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSentenceArea(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))
              ],
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              children: _fraseAtual.map((p) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: p.assetPath != null
                        ? Image.asset(p.assetPath!)
                        : Icon(p.icon, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(p.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, fontFamily: 'Quicksand')),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _falarFrase,
                  icon: const Icon(Icons.record_voice_over_rounded, size: 28),
                  label: const Text('OUVIR FRASE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => setState(() => _fraseAtual.clear()),
                  icon: Icon(Icons.delete_sweep_rounded, color: colorScheme.error, size: 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryMenu(ColorScheme colorScheme) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.0,
      ),
      itemCount: defaultPictogramCategories.length,
      itemBuilder: (context, index) {
        final cat = defaultPictogramCategories[index];
        return InkWell(
          onTap: () => setState(() => _selectedCategoryIndex = index),
          borderRadius: BorderRadius.circular(32),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: cat.color.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(color: cat.color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cat.icon, size: 50, color: cat.color),
                ),
                const SizedBox(height: 16),
                Text(cat.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cat.color, fontFamily: 'Quicksand')
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPictogramGrid(ColorScheme colorScheme) {
    final category = defaultPictogramCategories[_selectedCategoryIndex!];
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
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
    );
  }
}
