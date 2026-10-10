import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/child_profile.dart';
import '../../../services/speech_log_service.dart';
import '../../../models/speech_log_model.dart';
import '../../../services/ai_report_service.dart';
import '../../../services/report_service.dart';
import '../../../services/communication_log_service.dart';
import '../../../models/communication_log_model.dart';
import '../../../services/pdf_report_service.dart';

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
  final CommunicationLogService _commService = CommunicationLogService();
  final PdfReportService _pdfService = PdfReportService();
  final TextEditingController _notesController = TextEditingController();
  
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _performanceHistory = [];
  List<CommunicationLog> _commLogs = [];
  bool _loadingStats = true;
  bool _savingNotes = false;
  int _totalStars = 0;
  DateTime? _notesUpdatedAt;
  
  String? _parentMessage;
  DateTime? _parentMessageAt;
  
  String? _aiInsight;
  Map<String, dynamic>? _phonologicalMap;
  Map<String, dynamic>? _parentReportData;
  bool _generatingAi = false;
  bool _sendingToParent = false;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      await Future.wait([
        _loadStats(),
        _loadStarsNotesAndParentMessage(),
        _loadCommunicationLogs(),
      ]);
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
    }
  }

  Future<void> _loadCommunicationLogs() async {
    final logs = await _commService.getLogs(widget.child.id);
    if (mounted) setState(() => _commLogs = logs);
  }

  Future<void> _loadStarsNotesAndParentMessage() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('children').doc(widget.child.id).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _totalStars = data['progress']?['totalStars'] ?? 0;
          _notesController.text = (data['clinicalNotes'] ?? "").toString();
          _parentMessage = data['parentMessage']?.toString();
          if (data['notesUpdatedAt'] is Timestamp) _notesUpdatedAt = (data['notesUpdatedAt'] as Timestamp).toDate();
          if (data['parentMessageAt'] is Timestamp) _parentMessageAt = (data['parentMessageAt'] as Timestamp).toDate();
        });
      }
    } catch (e) {}
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(colorScheme),
          SliverToBoxAdapter(child: _buildTabBar(colorScheme)),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [_buildClinicalTab(colorScheme), _buildNotesTab(colorScheme)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: colorScheme.background,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: colorScheme.primary.withOpacity(0.2),
                  child: Icon(Icons.person, size: 40, color: colorScheme.primary)
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.child.name,
                        style: TextStyle(color: colorScheme.onBackground, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Quicksand')
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: colorScheme.secondary, borderRadius: BorderRadius.circular(12)),
                            child: Text(widget.child.diagnosis ?? 'TEA', style: TextStyle(color: colorScheme.onSecondary, fontSize: 10, fontWeight: FontWeight.w800))
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: widget.child.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ID da Criança copiado!'), duration: Duration(seconds: 1))
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorScheme.primary.withOpacity(0.2))
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.copy_rounded, size: 12, color: colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text('COPIAR ID', style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _statsBadge('ESTRELAS', _totalStars.toString(), Icons.stars, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statsBadge(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.amber, size: 28),
        Text(value, style: TextStyle(color: colorScheme.onBackground, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Quicksand')),
        Text(label, style: TextStyle(color: colorScheme.onBackground.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.w800))
      ]
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: colorScheme.primary,
        indicatorWeight: 4,
        tabs: const [Tab(text: 'ANALYTICS'), Tab(text: 'PRONTUÁRIO')]
      )
    );
  }

  Widget _buildClinicalTab(ColorScheme colorScheme) {
    if (_loadingStats) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildMiniKPI('Taxa de Acerto', '${((_stats?['success_rate'] ?? 0) * 100).toStringAsFixed(0)}%', Icons.trending_up, colorScheme.primary),
              const SizedBox(width: 16),
              _buildMiniKPI('Sessões', '${_stats?['total_sessions'] ?? 0}', Icons.event, colorScheme.secondary)
            ]
          ),
          const SizedBox(height: 32),
          if (_parentMessage != null && _parentMessage!.isNotEmpty) _buildProfessionalParentMessage(colorScheme),
          const SizedBox(height: 32),
          Text('HISTÓRICO DE ACERTOS (7 DIAS)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: colorScheme.onBackground.withOpacity(0.5), letterSpacing: 1.2)
          ),
          const SizedBox(height: 16),
          _buildEnhancedChart(colorScheme),
          const SizedBox(height: 32),
          _buildCommunicationHistorySection(colorScheme),
          const SizedBox(height: 32),
          _buildAiReportSection(colorScheme),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMiniKPI(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 22)
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Quicksand')),
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))
              ]
            )
          ]
        )
      )
    );
  }

  Widget _buildProfessionalParentMessage(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colorScheme.tertiary, width: 6)),
        color: colorScheme.tertiary.withOpacity(0.05),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OBSERVAÇÃO DA FAMÍLIA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: colorScheme.tertiary, letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(_parentMessage!, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87, fontFamily: 'Quicksand', fontWeight: FontWeight.w500))
        ]
      )
    );
  }

  Widget _buildCommunicationHistorySection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COMUNICAÇÃO FUNCIONAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: colorScheme.onBackground.withOpacity(0.5), letterSpacing: 1.2)),
        const SizedBox(height: 16),
        if (_commLogs.isEmpty)
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: const Center(child: Text('Nenhuma frase montada ainda.', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))))
        else
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: colorScheme.outline.withOpacity(0.1))),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _commLogs.take(5).length,
              separatorBuilder: (context, index) => Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
              itemBuilder: (context, index) {
                final log = _commLogs[index];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: colorScheme.primary.withOpacity(0.1), radius: 16, child: Icon(Icons.chat_bubble_outline, color: colorScheme.primary, size: 16)),
                  title: Text(log.sentence.join(' '), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Quicksand')),
                  subtitle: Text(DateFormat('dd/MM HH:mm').format(log.timestamp), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
                );
              }
            )
          )
      ]
    );
  }

  Widget _buildAiReportSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ANÁLISE CLÍNICA (IA)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: colorScheme.onBackground.withOpacity(0.5), letterSpacing: 1.2)), if (_aiInsight != null) IconButton(onPressed: _generateAiAnalysis, icon: Icon(Icons.refresh, size: 18, color: colorScheme.primary))]),
        const SizedBox(height: 16),
        if (_aiInsight == null && !_generatingAi) _buildAiPromptCard(colorScheme),
        if (_generatingAi) _buildSkeletonLoading(),
        if (_aiInsight != null) ...[
          _buildPhonologicalAnalysisTable(colorScheme),
          const SizedBox(height: 20),
          _buildActionPlanCard(colorScheme),
          const SizedBox(height: 24),
          _buildExecutiveSummary(colorScheme),
          const SizedBox(height: 24),
          _buildSharedAction(colorScheme),
        ],
      ],
    );
  }

  Widget _buildAiPromptCard(ColorScheme colorScheme) {
    return InkWell(
      onTap: _generateAiAnalysis,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: const Column(
          children: [
            Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 32),
            SizedBox(height: 12),
            Text('Gerar Diagnóstico IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Quicksand')),
            Text('Análise concisa e conduta clínica', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
          ]
        )
      )
    );
  }

  Widget _buildExecutiveSummary(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.summarize_rounded, color: colorScheme.primary, size: 18), const SizedBox(width: 8), Text('INSIGHT OBJETIVO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: colorScheme.primary))]),
          const SizedBox(height: 12),
          Text(_aiInsight ?? '', style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF2D3436), fontWeight: FontWeight.w600, fontFamily: 'Quicksand'))
        ]
      )
    );
  }

  Widget _buildPhonologicalAnalysisTable(ColorScheme colorScheme) {
    if (_phonologicalMap == null) return const SizedBox.shrink();
    
    final List patterns = _phonologicalMap!['patterns'] ?? [];
    final String summary = _phonologicalMap!['summary'] ?? "Análise fonológica completa.";
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.orange[200]!, width: 2)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text('MAPA FONOLÓGICO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 16),
          if (_phonologicalMap!['status'] == 'sem_dados')
             const Text('A IA não detectou erros nítidos o suficiente.', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))
          else ...[
            Text(summary, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w700, fontFamily: 'Quicksand')),
            const Divider(height: 32),
            ...patterns.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: colorScheme.background, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: Colors.white, radius: 18, child: Text(p['target'] ?? '?', style: TextStyle(color: colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w900))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['process'] ?? 'Padrão Identificado', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, fontFamily: 'Quicksand')),
                          Text('Alvo: "${p['target']}" | Criança: "${p['spoken']}"', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionPlanCard(ColorScheme colorScheme) {
    if (_phonologicalMap == null || _phonologicalMap!['intervention'] == null) return const SizedBox.shrink();
    final intervention = _phonologicalMap!['intervention'];
    String tip = intervention is Map ? (intervention['pedagogical_tip'] ?? '') : intervention.toString();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colorScheme.secondary.withOpacity(0.2), borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.lightbulb_outline_rounded, color: colorScheme.onSecondary, size: 20), const SizedBox(width: 8), Text('PLANO DE TREINO SUGERIDO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: colorScheme.onSecondary))]),
          const SizedBox(height: 12),
          Text(tip, style: TextStyle(fontSize: 14, height: 1.7, color: colorScheme.onSecondary, fontWeight: FontWeight.w600, fontFamily: 'Quicksand'))
        ]
      )
    );
  }

  Widget _buildSharedAction(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _sendingToParent ? null : _sendToParent,
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('FAMÍLIA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            )
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _exportingPdf ? null : _exportToPdf,
            icon: _exportingPdf
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('PDF', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onBackground,
              side: BorderSide(color: colorScheme.outline.withOpacity(0.3), width: 2),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            )
          ),
        ),
      ],
    );
  }

  Widget _buildNotesTab(ColorScheme colorScheme) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(hintText: 'Digite as notas clínicas...', border: InputBorder.none, fillColor: Colors.transparent),
              style: const TextStyle(fontSize: 16, height: 1.7, fontFamily: 'Quicksand', fontWeight: FontWeight.w500)
            )
          ),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_notesUpdatedAt != null)
                Text('Sincronizado: ${DateFormat('HH:mm').format(_notesUpdatedAt!)}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(
                onPressed: _savingNotes ? null : _saveClinicalNotes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.onBackground,
                  foregroundColor: colorScheme.background,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))
                ),
                child: _savingNotes ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('SALVAR NOTA')
              )
            ]
          )
        ]
      )
    );
  }

  Future<void> _generateAiAnalysis() async {
    setState(() => _generatingAi = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('children')
          .doc(widget.child.id)
          .collection('speech_logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final List<SpeechLog> logs = snapshot.docs.map((doc) => SpeechLog.fromMap(doc.data())).toList();
      
      final results = await Future.wait([
        _aiService.generateClinicalInsight(widget.child, logs, _performanceHistory), 
        _aiService.generatePhonologicalMap(logs), 
        _aiService.generateParentReport(widget.child, logs)
      ]);
      
      if (mounted) {
        setState(() { 
          _aiInsight = results[0].toString(); 
          _phonologicalMap = results[1] as Map<String, dynamic>?; 
          _parentReportData = results[2] as Map<String, dynamic>?; 
        });
      }
    } catch (e) {
      debugPrint("Erro ao gerar análise IA: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar análise da IA: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generatingAi = false);
      }
    }
  }

  Future<void> _exportToPdf() async {
    setState(() => _exportingPdf = true);
    try {
      await _pdfService.generateAndShareReport(
        child: widget.child,
        clinicalInsight: _aiInsight,
        phonologicalMap: _phonologicalMap,
        stats: _stats,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar PDF: $e'))
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _sendToParent() async { if (_parentReportData == null) return; setState(() => _sendingToParent = true); final success = await _reportService.sendReportToParent(widget.child.id, _parentReportData!); if (mounted) setState(() { _sendingToParent = false; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Enviado!' : 'Erro'))); }); }

  Future<void> _saveClinicalNotes() async { setState(() => _savingNotes = true); await FirebaseFirestore.instance.collection('children').doc(widget.child.id).update({'clinicalNotes': _notesController.text, 'notesUpdatedAt': FieldValue.serverTimestamp()}); if (mounted) setState(() { _savingNotes = false; _notesUpdatedAt = DateTime.now(); }); }

  Widget _buildSkeletonLoading() { return Container(width: double.infinity, padding: const EdgeInsets.all(40), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)), child: const Column(children: [CircularProgressIndicator(), SizedBox(height: 20), Text('IA analisando histórico...', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))])); }

  Widget _buildEnhancedChart(ColorScheme colorScheme) {
    if (_performanceHistory.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1))
        ),
        child: const Center(
          child: Text('Sem dados de treino nos últimos 7 dias.',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)
          )
        ),
      );
    }

    return Container(
      height: 240,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)]
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[100]!, strokeWidth: 1)
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < _performanceHistory.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_performanceHistory[index]['day'],
                        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}%',
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: _performanceHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['rate'] ?? 0).toDouble())).toList(),
              isCurved: true,
              color: colorScheme.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: colorScheme.primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colorScheme.primary.withOpacity(0.2), colorScheme.primary.withOpacity(0)]
                )
              )
            )
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => colorScheme.primary,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final data = _performanceHistory[spot.x.toInt()];
                  return LineTooltipItem(
                    '${data['rate'].toStringAsFixed(0)}% de acerto\n${data['count']} tentativas',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        )
      )
    );
  }
}
