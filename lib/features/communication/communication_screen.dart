import 'package:flutter/material.dart';
import '../settings/settings_screen.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final List<String> _fraseAtual = [];

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
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    onPressed: _fraseAtual.isNotEmpty
                        ? () => _falarFrase()
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade400,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: _fraseAtual.isNotEmpty
                        ? () => setState(() => _fraseAtual.clear())
                        : null,
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
                              onTap: () {
                                setState(() {
                                  _fraseAtual.add(pictograma);
                                });
                              },
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

  void _falarFrase() {
    // Aqui vamos implementar a síntese de voz depois
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Falando: ${_fraseAtual.join(' ')}')),
    );
  }
}