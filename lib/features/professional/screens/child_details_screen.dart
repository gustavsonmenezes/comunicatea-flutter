import 'package:flutter/material.dart';
import '../../../models/child_profile.dart';
import '../../../services/speech_log_service.dart';
import '../../../models/speech_log_model.dart';
import '../../../services/ai_report_service.dart'; // 🔥 Importação do serviço de IA

class ChildDetailsScreen extends StatefulWidget {
  final ChildProfile child;
  const ChildDetailsScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> {
  final SpeechLogService _logService = SpeechLogService();
  final AiReportService _aiService = AiReportService(); // 🔥 Instância do serviço de IA
  
  Map<String, dynamic>? _stats;
  bool _loadingStats = true;
  String? _aiInsight; // 🔥 Guarda o texto da IA
  bool _generatingAi = false; // 🔥 Controle de carregamento da IA

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _logService.getChildStatistics(widget.child.id);
    if (mounted) {
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    }
  }

  // 🔥 Função para chamar o Gemini
  Future<void> _generateAiInsight() async {
    setState(() {
      _generatingAi = true;
      _aiInsight = null;
    });

    final List<SpeechLog> logs = _stats?['recent_logs'] ?? [];
    final insight = await _aiService.generateClinicalInsight(widget.child, logs);

    if (mounted) {
      setState(() {
        _aiInsight = insight;
        _generatingAi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monitoramento: ${widget.child.name}'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _loadingStats 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHighlights(),
                  const SizedBox(height: 20),
                  
                  // 🔥 NOVO: ÁREA DE IA GENERATIVA
                  _buildAiInsightSection(),
                  
                  const SizedBox(height: 24),
                  _buildWordPerformance(),
                  const SizedBox(height: 24),
                  _buildRecentActivity(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildAiInsightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_aiInsight == null && !_generatingAi)
          ElevatedButton.icon(
            onPressed: _generateAiInsight,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('GERAR INSIGHT CLÍNICO COM IA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[50],
              foregroundColor: Colors.blue[800],
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue[300]!),
              ),
            ),
          ),
        
        if (_generatingAi)
          Card(
            color: Colors.blue[50],
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(height: 12),
                  Text('O Gemini está analisando os dados de fala...', style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),

        if (_aiInsight != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[800],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text('INSIGHT DA IA (Gemini 1.5)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _aiInsight!,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => setState(() => _aiInsight = null),
                    child: const Text('LIMPAR', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHighlights() {
    return Row(
      children: [
        _highlightCard('1ª Palavra', _stats?['first_word'], Icons.star_border, Colors.orange),
        const SizedBox(width: 8),
        _highlightCard('Melhor Pronúncia', _stats?['easiest_word'], Icons.check_circle_outline, Colors.green),
        const SizedBox(width: 8),
        _highlightCard('Maior Desafio', _stats?['hardest_word'], Icons.warning_amber_rounded, Colors.red),
      ],
    );
  }

  Widget _highlightCard(String label, String? value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value ?? '-', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600]), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordPerformance() {
    final List<dynamic> wordStats = _stats?['word_stats'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DESEMPENHO POR PALAVRA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12)),
        const SizedBox(height: 8),
        if (wordStats.isEmpty) 
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Sem dados de fala suficientes'))),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: wordStats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final stat = wordStats[index];
              final double rate = stat['success_rate'];
              
              return ListTile(
                title: Text(stat['word'], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${stat['attempts']} tentativas'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${(rate * 100).toStringAsFixed(0)}% acerto', 
                      style: TextStyle(color: _getRateColor(rate), fontWeight: FontWeight.bold)),
                    SizedBox(
                      width: 70,
                      child: LinearProgressIndicator(
                        value: rate,
                        backgroundColor: Colors.grey[200],
                        color: _getRateColor(rate),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getRateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildRecentActivity() {
    final List<SpeechLog> logs = _stats?['recent_logs'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HISTÓRICO RECENTE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12)),
        const SizedBox(height: 8),
        if (logs.isEmpty) const Text('Nenhuma atividade recente'),
        ...logs.map((log) => ListTile(
          dense: true,
          leading: Icon(log.isSuccess ? Icons.check_circle : Icons.error_outline, 
                       color: log.isSuccess ? Colors.green : Colors.red, size: 20),
          title: Text(log.targetWord, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text('Reconhecido: "${log.recognizedWords}"'),
          trailing: Text('${log.timestamp.day}/${log.timestamp.month} ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, "0")}', 
                         style: const TextStyle(fontSize: 10, color: Colors.grey)),
        )).toList(),
      ],
    );
  }
}
