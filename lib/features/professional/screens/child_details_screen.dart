import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/child_profile.dart';
import '../../../services/speech_log_service.dart';
import '../../../models/speech_log_model.dart';
import '../../../services/ai_report_service.dart';

class ChildDetailsScreen extends StatefulWidget {
  final ChildProfile child;
  const ChildDetailsScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> {
  final SpeechLogService _logService = SpeechLogService();
  final AiReportService _aiService = AiReportService();
  
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _performanceHistory = [];
  bool _loadingStats = true;
  
  String? _aiInsight;
  Map<String, dynamic>? _phonologicalMap;
  bool _generatingAi = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _logService.getChildStatistics(widget.child.id);
    final history = await _logService.getPerformanceHistory(widget.child.id);
    
    if (mounted) {
      setState(() {
        _stats = stats;
        _performanceHistory = history;
        _loadingStats = false;
      });
    }
  }

  Future<void> _generateAiAnalysis() async {
    setState(() {
      _generatingAi = true;
      _aiInsight = null;
      _phonologicalMap = null;
    });

    final List<SpeechLog> logs = _stats?['recent_logs'] ?? [];
    
    final results = await Future.wait([
      _aiService.generateClinicalInsight(widget.child, logs, _performanceHistory),
      _aiService.generatePhonologicalMap(logs),
    ]);

    if (mounted) {
      setState(() {
        _aiInsight = results[0] as String;
        _phonologicalMap = results[1] as Map<String, dynamic>;
        _generatingAi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.child.name),
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
                  const SizedBox(height: 24),
                  _buildPerformanceChart(),
                  const SizedBox(height: 24),
                  
                  if (_aiInsight == null && !_generatingAi)
                    _buildAiActionButton(),

                  if (_generatingAi)
                    _buildAiLoadingState(),

                  if (_aiInsight != null) ...[
                    _buildAiInsightCard(),
                    const SizedBox(height: 16),
                    _buildPhonologicalMapCard(),
                    const SizedBox(height: 16),
                    _buildInterventionPlanCard(), // 🔥 NOVO: Plano de Intervenção
                  ],
                  
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

  Widget _buildInterventionPlanCard() {
    if (_phonologicalMap == null || _phonologicalMap!['intervention'] == null) {
      return const SizedBox.shrink();
    }

    final intervention = _phonologicalMap!['intervention'];
    final suggestedWords = (intervention['suggested_words'] as List? ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, color: Colors.green[800], size: 20),
              const SizedBox(width: 8),
              Text('PLANO DE INTERVENÇÃO SUGERIDO', 
                style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          
          const Text('Palavras para Treino Fonético:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: suggestedWords.map((word) => Chip(
              label: Text(word.toString()),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
              side: BorderSide(color: Colors.green[100]!),
            )).toList(),
          ),
          
          const SizedBox(height: 16),
          const Text('Dica Pedagógica / Técnica:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(intervention['pedagogical_tip'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.flag, color: Colors.orange[800], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Meta: ${intervention['weekly_goal']}',
                    style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiActionButton() {
    return ElevatedButton.icon(
      onPressed: _generateAiAnalysis,
      icon: const Icon(Icons.auto_awesome),
      label: const Text('GERAR ANÁLISE E PLANO DE TREINO'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[50],
        foregroundColor: Colors.blue[800],
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue[300]!),
        ),
      ),
    );
  }

  Widget _buildAiLoadingState() {
    return Card(
      color: Colors.blue[50],
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 12),
            Text('A IA está analisando fonemas e criando o plano de treino...', 
              style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('ANÁLISE DE TENDÊNCIA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_aiInsight!, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildPhonologicalMapCard() {
    if (_phonologicalMap == null || _phonologicalMap!['status'] == 'sem_dados') {
      return const SizedBox.shrink();
    }

    final patterns = (_phonologicalMap!['patterns'] as List? ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.record_voice_over, color: Colors.orange[800], size: 20),
              const SizedBox(width: 8),
              Text('MAPEAMENTO DE SONS (FONOLOGIA)', 
                style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          if (patterns.isEmpty)
            const Text('Nenhum padrão de troca detectado ainda.', style: TextStyle(fontSize: 13, color: Colors.grey)),
          
          ...patterns.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                  child: Text(p['target'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                  child: Text(p['spoken'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['process'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${p['count']} ocorrências', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
          
          if (_phonologicalMap!['summary'] != null) ...[
            const Divider(),
            Text(
              _phonologicalMap!['summary'],
              style: TextStyle(fontSize: 12, color: Colors.grey[800], fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    if (_performanceHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EVOLUÇÃO DOS ÚLTIMOS 7 DIAS', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12)),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.fromLTRB(8, 24, 24, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= _performanceHistory.length) return const SizedBox();
                      return Text(_performanceHistory[index]['day'], style: const TextStyle(fontSize: 10, color: Colors.grey));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _performanceHistory.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value['rate']);
                  }).toList(),
                  isCurved: true,
                  color: Colors.blue[800],
                  barWidth: 4,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue[800]!.withOpacity(0.1),
                  ),
                ),
              ],
              minY: 0,
              maxY: 100,
            ),
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
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
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
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
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
