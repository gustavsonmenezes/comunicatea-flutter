import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class SpeechStatsScreen extends StatefulWidget {
  const SpeechStatsScreen({Key? key}) : super(key: key);

  @override
  State<SpeechStatsScreen> createState() => _SpeechStatsScreenState();
}

class _SpeechStatsScreenState extends State<SpeechStatsScreen> {
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = true;
  int _totalWords = 0;
  List<Map<String, dynamic>> _recentPhrases = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Aqui você pode implementar uma busca de logs de fala no seu DatabaseService
        // Por enquanto, vamos simular o carregamento para o app não travar
        await Future.delayed(const Duration(milliseconds: 500));

        setState(() {
          _totalWords = 0; // Vincular ao seu contador real futuramente
          _recentPhrases = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar estatísticas: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas de Fala'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCard('Total de Palavras/Pictogramas', '$_totalWords', Icons.record_voice_over, Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Frases Recentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _recentPhrases.isEmpty
                ? const Center(child: Text('Nenhuma atividade recente registrada.'))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentPhrases.length,
              itemBuilder: (context, index) {
                final item = _recentPhrases[index];
                return ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(item['text'] ?? ''),
                  subtitle: Text(item['timestamp'] ?? ''),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
