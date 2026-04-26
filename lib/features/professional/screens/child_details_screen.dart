import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/child_profile.dart';
import '../../../services/speech_log_service.dart';
import '../../../models/speech_log_model.dart';
import '../../../services/ai_report_service.dart';
import '../../../services/report_service.dart';

class ChildDetailsScreen extends StatefulWidget {
  final ChildProfile child;
  const ChildDetailsScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SpeechLogService _logService = SpeechLogService();
  final AiReportService _aiService = AiReportService();
  final ReportService _reportService = ReportService();
  final TextEditingController _notesController = TextEditingController();
  
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _performanceHistory = [];
  bool _loadingStats = true;
  bool _savingNotes = false;
  int _totalStars = 0;
  DateTime? _notesUpdatedAt;
  
  String? _parentMessage; // 🔥 MENSAGEM DO PAI
  DateTime? _parentMessageAt;
  
  String? _aiInsight;
  Map<String, dynamic>? _phonologicalMap;
  Map<String, dynamic>? _parentReportData;
  bool _generatingAi = false;
  bool _sendingToParent = false;

  final Color _primaryBlue = const Color(0xFF1E3A8A);
  final Color _accentPurple = const Color(0xFF7C3AED);
  final Color _bgGray = const Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadStats(),
      _loadStarsNotesAndParentMessage(),
    ]);
  }

  Future<void> _loadStarsNotesAndParentMessage() async {
    final doc = await FirebaseFirestore.instance.collection('children').doc(widget.child.id).get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      setState(() {
        _totalStars = data['progress']?['totalStars'] ?? 0;
        _notesController.text = data['clinicalNotes'] ?? "";
        _parentMessage = data['parentMessage']; // 🔥 LENDO MENSAGEM DO PAI
        
        if (data['notesUpdatedAt'] != null) {
          _notesUpdatedAt = (data['notesUpdatedAt'] as Timestamp).toDate();
        }
        if (data['parentMessageAt'] != null) {
          _parentMessageAt = (data['parentMessageAt'] as Timestamp).toDate();
        }
      });
    }
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

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.child.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('Painel de Acompanhamento Clínico', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'ANÁLISE E EVOLUÇÃO'),
            Tab(text: 'PRONTUÁRIO'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEvolutionTab(),
          _buildNotesTab(),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 NOVO: SEÇÃO DE MENSAGEM DA FAMÍLIA
          if (_parentMessage != null && _parentMessage!.isNotEmpty) ...[
            _buildSectionHeader('Recado da Família'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.family_restroom, color: Colors.purple[700], size: 20),
                      const SizedBox(width: 8),
                      Text('ENVIADO PELOS PAIS', style: TextStyle(color: Colors.purple[800], fontWeight: FontWeight.bold, fontSize: 11)),
                      const Spacer(),
                      if (_parentMessageAt != null)
                        Text(DateFormat('dd/MM HH:mm').format(_parentMessageAt!), style: TextStyle(fontSize: 10, color: Colors.purple[300])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_parentMessage!, style: TextStyle(fontSize: 15, color: Colors.purple[900], height: 1.4, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Minhas Notas Clínicas'),
              if (_notesUpdatedAt != null)
                Text('Última edição: ${DateFormat('dd/MM HH:mm').format(_notesUpdatedAt!)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Registre aqui a evolução da sessão...',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _savingNotes ? null : _saveClinicalNotes,
              icon: _savingNotes ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
              label: const Text('ATUALIZAR PRONTUÁRIO'),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            ),
          ),
        ],
      ),
    );
  }

  // --- RESTO DOS MÉTODOS DE UI MANTIDOS ---
  
  Widget _buildEvolutionTab() {
    if (_loadingStats) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickSummaryHeader(),
            const SizedBox(height: 24),
            _buildSectionHeader('Indicadores de Desempenho'),
            const SizedBox(height: 12),
            _buildPerformanceChart(),
            const SizedBox(height: 24),
            _buildSectionHeader('Inteligência Artificial (IA)'),
            const SizedBox(height: 12),
            if (_aiInsight == null && !_generatingAi) _buildAiActionButton(),
            if (_generatingAi) _buildAiLoadingState(),
            if (_aiInsight != null) ...[
              _buildAiInsightCard(),
              const SizedBox(height: 16),
              _buildPhonologicalMapCard(),
              const SizedBox(height: 16),
              _buildInterventionPlanCard(),
              const SizedBox(height: 24),
              _buildSendToParentButton(),
            ],
            const SizedBox(height: 24),
            _buildSectionHeader('Vocabulário e Atividade'),
            const SizedBox(height: 12),
            _buildWordPerformance(),
            const SizedBox(height: 16),
            _buildRecentActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSummaryHeader() {
    return Row(
      children: [
        _summaryCard('Estrelas', '$_totalStars', Icons.stars, Colors.amber[700]!),
        const SizedBox(width: 12),
        _summaryCard('Sessões', '${_stats?['total_sessions'] ?? 0}', Icons.event_available, Colors.blue[600]!),
        const SizedBox(width: 12),
        _summaryCard('Acerto', '${((_stats?['success_rate'] ?? 0) * 100).toStringAsFixed(0)}%', Icons.trending_up, Colors.green[600]!),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title.toUpperCase(), 
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey[400], letterSpacing: 1.2));
  }

  Widget _buildPerformanceChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _performanceHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['rate'])).toList(),
              isCurved: true,
              color: _primaryBlue,
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: _primaryBlue.withOpacity(0.05)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiActionButton() {
    return InkWell(
      onTap: _generateAiAnalysis,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFF3B82F6), _primaryBlue]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: const Column(
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 32),
            SizedBox(height: 12),
            Text('Gerar Diagnóstico por IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Analisa padrões fonológicos e gera plano de treino', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
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
      _aiService.generateParentReport(widget.child, logs),
    ]);
    if (mounted) {
      setState(() {
        _aiInsight = results[0] as String;
        _phonologicalMap = results[1] as Map<String, dynamic>;
        _parentReportData = results[2] as Map<String, dynamic>;
        _generatingAi = false;
      });
    }
  }

  Widget _buildAiInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _primaryBlue, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.psychology, color: Colors.white, size: 20), SizedBox(width: 8), Text('INSIGHT CLÍNICO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))]),
          const SizedBox(height: 12),
          Text(_aiInsight ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPhonologicalMapCard() {
    if (_phonologicalMap == null || _phonologicalMap!['status'] == 'sem_dados') return const SizedBox.shrink();
    final patterns = (_phonologicalMap!['patterns'] as List? ?? []);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.orange[100]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MAPA FONOLÓGICO', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 16),
          ...patterns.map((p) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: Colors.red[50], child: Text(p['target'], style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
            title: Text(p['process'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Substitui por: ${p['spoken']}'),
            trailing: Badge(label: Text('${p['count']}'), backgroundColor: Colors.orange),
          )),
        ],
      ),
    );
  }

  Widget _buildInterventionPlanCard() {
    if (_phonologicalMap == null || _phonologicalMap!['intervention'] == null) return const SizedBox.shrink();
    final intervention = _phonologicalMap!['intervention'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.green[100]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PLANO DE TREINO SUGERIDO', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 12),
          Text(intervention['pedagogical_tip'] ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF166534))),
          const SizedBox(height: 16),
          Wrap(spacing: 8, children: (intervention['suggested_words'] as List).map((w) => Chip(label: Text(w.toString(), style: const TextStyle(fontSize: 11)), backgroundColor: Colors.white)).toList()),
        ],
      ),
    );
  }

  Widget _buildSendToParentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _sendingToParent ? null : _sendToParent,
        icon: const Icon(Icons.family_restroom),
        label: const Text('COMPARTILHAR COM A FAMÍLIA'),
        style: ElevatedButton.styleFrom(backgroundColor: _accentPurple, foregroundColor: Colors.white, padding: const EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
    );
  }

  Future<void> _sendToParent() async {
    if (_parentReportData == null) return;
    setState(() => _sendingToParent = true);
    final success = await _reportService.sendReportToParent(widget.child.id, _parentReportData!);
    if (mounted) {
      setState(() => _sendingToParent = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Enviado!' : 'Erro'), backgroundColor: success ? Colors.green : Colors.red));
    }
  }

  Future<void> _saveClinicalNotes() async {
    setState(() => _savingNotes = true);
    await FirebaseFirestore.instance.collection('children').doc(widget.child.id).update({
      'clinicalNotes': _notesController.text,
      'notesUpdatedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      setState(() {
        _savingNotes = false;
        _notesUpdatedAt = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prontuário atualizado!')));
    }
  }

  Widget _buildWordPerformance() {
    final List<dynamic> wordStats = _stats?['word_stats'] ?? [];
    if (wordStats.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: wordStats.take(3).map((stat) => ListTile(
          title: Text(stat['word'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${stat['attempts']} tentativas'),
          trailing: Text('${(stat['success_rate'] * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        )).toList(),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    final List<SpeechLog> logs = _stats?['recent_logs'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: logs.take(5).map((log) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(log.isSuccess ? Icons.check_circle : Icons.error, color: log.isSuccess ? Colors.green : Colors.red, size: 16),
            const SizedBox(width: 12),
            Text(log.targetWord, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(DateFormat('dd/MM HH:mm').format(log.timestamp), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildAiLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(24)),
      child: const Column(children: [CircularProgressIndicator(), SizedBox(height: 16), Text('A IA está analisando padrões fonológicos...')]),
    );
  }
}
