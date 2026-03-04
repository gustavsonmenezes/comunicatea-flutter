import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../settings/settings_screen.dart';
import '../../models/pictogram_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pictogram_card.dart';
import '../../widgets/phrase_bar.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final List<String> _fraseAtual = [];
  FlutterTts? _flutterTts;
  bool _isSpeaking = false;
  bool _isTtsInitialized = false;
  int _selectedCategoryIndex = 0;
  double _pictogramSize = 100;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    try {
      FlutterTts flutterTts = FlutterTts();
      await flutterTts.setLanguage("pt-BR");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setPitch(1.0);
      await flutterTts.setVolume(1.0);

      flutterTts.setStartHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
          });
        }
      });

      flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
        print("Erro no TTS: $msg");
      });

      setState(() {
        _flutterTts = flutterTts;
        _isTtsInitialized = true;
      });

      print("TTS inicializado com sucesso!");
    } catch (e) {
      print("Erro ao inicializar TTS: $e");
      setState(() {
        _isTtsInitialized = false;
      });
    }
  }

  Future<void> _falar(String texto) async {
    if (texto.isEmpty) return;

    if (!_isTtsInitialized || _flutterTts == null) {
      _mostrarErroTts();
      return;
    }

    try {
      if (_isSpeaking) {
        await _flutterTts!.stop();
      }
      await _flutterTts!.speak(texto);
    } catch (e) {
      print("Erro ao falar: $e");
      _mostrarErroTts();
    }
  }

  void _mostrarErroTts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Síntese de voz não disponível no momento.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _falarFrase() {
    if (_fraseAtual.isEmpty) return;
    final frase = _fraseAtual.join(' ');
    _falar(frase);
  }

  void _adicionarPictograma(String pictograma) {
    setState(() {
      _fraseAtual.add(pictograma);
    });
    _falar(pictograma);
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

  void _pararFala() {
    if (_isSpeaking) {
      _flutterTts?.stop();
    }
  }

  @override
  void dispose() {
    _flutterTts?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory = defaultCategories[_selectedCategoryIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('COMUNICA-TEA'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de frase
          PhraseBar(
            phrase: _fraseAtual,
            isSpeaking: _isSpeaking,
            onSpeak: _isSpeaking ? _pararFala : _falarFrase,
            onClear: _limparFrase,
            onRemoveLast: _removerUltimoPictograma,
            isEnabled: _isTtsInitialized,
          ),

          // Abas de categorias
          Container(
            height: 100,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: defaultCategories.length,
              itemBuilder: (context, index) {
                return CategoryTab(
                  category: defaultCategories[index],
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

          // Grade de pictogramas
          Expanded(
            child: Container(
              color: AppTheme.backgroundColor,
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: currentCategory.pictograms.length,
                itemBuilder: (context, index) {
                  final pictogram = currentCategory.pictograms[index];
                  return PictogramCard(
                    pictogram: pictogram,
                    categoryColor: currentCategory.color,
                    size: _pictogramSize,
                    onTap: () => _adicionarPictograma(pictogram.label),
                    onLongPress: () => _falar(pictogram.label),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
