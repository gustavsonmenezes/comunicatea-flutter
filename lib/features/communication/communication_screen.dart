import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../settings/settings_screen.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final List<String> _fraseAtual = [];
  FlutterTts? _flutterTts; // Mudamos para nullable com ?
  bool _isSpeaking = false;
  bool _isTtsInitialized = false; // Flag para saber se já inicializou

  // Lista de categorias com pictogramas
  final List<Map<String, dynamic>> categorias = [
    {
      'nome': 'Necessidades',
      'icone': Icons.local_drink,
      'cor': Colors.blue,
      'pictogramas': ['Água', 'Comida', 'Banheiro', 'Descansar']
    },
    {
      'nome': 'Sentimentos',
      'icone': Icons.emoji_emotions,
      'cor': Colors.red,
      'pictogramas': ['Feliz', 'Triste', 'Bravo', 'Cansado']
    },
    {
      'nome': 'Ações',
      'icone': Icons.directions_run,
      'cor': Colors.green,
      'pictogramas': ['Brincar', 'Comer', 'Dormir', 'Estudar']
    },
    {
      'nome': 'Pessoas',
      'icone': Icons.people,
      'cor': Colors.purple,
      'pictogramas': ['Mamãe', 'Papai', 'Amigo', 'Professor']
    },
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    try {
      FlutterTts flutterTts = FlutterTts();

      // Configurar o idioma para português do Brasil
      await flutterTts.setLanguage("pt-BR");

      // Configurar velocidade da fala (0.0 a 1.0)
      await flutterTts.setSpeechRate(0.5);

      // Configurar tom da voz (0.0 a 2.0)
      await flutterTts.setPitch(1.0);

      // Configurar volume (0.0 a 1.0)
      await flutterTts.setVolume(1.0);

      // Listeners para saber quando começa/termina de falar
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

    // Verifica se o TTS foi inicializado
    if (!_isTtsInitialized || _flutterTts == null) {
      _mostrarErroTts();
      return;
    }

    try {
      // Para se já estiver falando
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
    // Falar o pictograma individual ao clicar
    _falar(pictograma);
  }

  void _limparFrase() {
    setState(() {
      _fraseAtual.clear();
    });
  }

  @override
  void dispose() {
    _flutterTts?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COMUNICA-TEA'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
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
          // Barra de frase atual
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _fraseAtual.isEmpty
                          ? 'Toque nos pictogramas para se comunicar'
                          : _fraseAtual.join(' '),
                      style: TextStyle(
                        fontSize: 18,
                        color: _fraseAtual.isEmpty ? Colors.grey.shade600 : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade700,
                  child: IconButton(
                    icon: Icon(
                      _isSpeaking ? Icons.stop : Icons.volume_up,
                      color: Colors.white,
                    ),
                    onPressed: _fraseAtual.isNotEmpty
                        ? (_isSpeaking ? _flutterTts?.stop : _falarFrase)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade400,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: _fraseAtual.isNotEmpty ? _limparFrase : null,
                  ),
                ),
              ],
            ),
          ),

          // Lista de categorias
          Expanded(
            child: ListView.builder(
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final categoria = categorias[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: categoria['cor'],
                      child: Icon(categoria['icone'], color: Colors.white),
                    ),
                    title: Text(
                      categoria['nome'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categoria['pictogramas'].map<Widget>((pictograma) {
                            return GestureDetector(
                              onTap: () => _adicionarPictograma(pictograma),
                              onLongPress: () => _falar(pictograma),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: categoria['cor'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: categoria['cor']),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 40,
                                      color: categoria['cor'],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pictograma,
                                      style: TextStyle(color: categoria['cor']),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}