import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/report_service.dart';
import '../../services/auth_service.dart';
import '../../services/speech_log_service.dart';
import '../stickers/services/sticker_service.dart';
import '../stickers/models/sticker_model.dart';
import '../../models/child_profile.dart';
import '../auth/screens/login_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  final ChildProfile child;
  const ParentDashboardScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final ReportService _reportService = ReportService();
  final StickerService _stickerService = StickerService();
  final SpeechLogService _logService = SpeechLogService();
  
  bool _loading = true;
  Map<String, dynamic>? _parentReport;
  String _childName = "Carregando...";
  List<StickerModel> _recentStickers = [];
  int _activeDaysThisWeek = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final childDoc = await FirebaseFirestore.instance.collection('children').doc(widget.child.id).get();
      if (childDoc.exists && mounted) {
        setState(() => _childName = childDoc.data()?['name'] ?? "Criança");
      }

      final report = await _reportService.getLatestReport(widget.child.id);
      final allStickers = await _stickerService.getStickers(widget.child.id);
      final unlockedStickers = allStickers.where((s) => s.isUnlocked).toList();
      
      final history = await _logService.getPerformanceHistory(widget.child.id);
      final activeDays = history.length;

      if (mounted) {
        setState(() {
          _parentReport = report;
          _recentStickers = unlockedStickers.reversed.take(4).toList();
          _activeDaysThisWeek = activeDays;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleLogout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Área da Família'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            setState(() => _loading = true);
            _loadData();
          }),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _showLogoutDialog()),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(),
                const SizedBox(height: 24),
                _buildEngagementCard(),
                const SizedBox(height: 24),
                if (_parentReport != null) ...[
                  _buildHighlightCard(),
                  const SizedBox(height: 16),
                  _buildHomeActivityCard(),
                  const SizedBox(height: 16),
                  _buildWordOfTheWeek(),
                ] else 
                  _buildEmptyState(),
                const SizedBox(height: 24),
                _buildStickersMural(),
                const SizedBox(height: 32),
                _buildUsageTip(),
              ],
            ),
          ),
    );
  }

  Widget _buildEngagementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blue[100]!)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle), child: Icon(Icons.calendar_today, color: Colors.blue[800])),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DEDICAÇÃO NA SEMANA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
          Text('$_activeDaysThisWeek de 7 dias praticando', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _activeDaysThisWeek / 7, backgroundColor: Colors.blue[50], color: Colors.blue[400]),
        ])),
      ]),
    );
  }

  Widget _buildStickersMural() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CONQUISTAS RECENTES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_recentStickers.isEmpty)
          const Text('Ainda não há figurinhas desbloqueadas.', style: TextStyle(fontSize: 12, color: Colors.grey))
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recentStickers.length,
              itemBuilder: (context, index) {
                final sticker = _recentStickers[index];
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                  child: Center(child: Image.asset(sticker.imagePath, width: 50)), // 🔥 Corrigido para imagePath
                );
              },
            ),
          ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('NÃO')),
          TextButton(onPressed: _handleLogout, child: const Text('SIM')),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Olá, família do $_childName! 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const Text('Acompanhe o desenvolvimento em casa.', style: TextStyle(fontSize: 14, color: Colors.grey)),
    ]);
  }

  Widget _buildHighlightCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple[600]!, Colors.purple[400]!]), borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('DESTAQUE DA SEMANA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 12),
        Text(_parentReport!['highlight'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_parentReport!['message'] ?? '', style: TextStyle(color: Colors.purple[50], fontSize: 14)),
      ]),
    );
  }

  Widget _buildHomeActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[200]!)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ATIVIDADE PARA CASA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12)),
        const SizedBox(height: 12),
        Text(_parentReport!['home_activity'] ?? '', style: const TextStyle(fontSize: 15, color: Color(0xFF4F5D75))),
      ]),
    );
  }

  Widget _buildWordOfTheWeek() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PALAVRA FOCO', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
          Text(_parentReport!['word_of_the_week'] ?? '-', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
        ])),
        const Icon(Icons.record_voice_over, color: Colors.blue, size: 40),
      ]),
    );
  }

  Widget _buildUsageTip() {
    return const Center(child: Text('O apoio da família é fundamental para o progresso.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)));
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('Aguardando relatório do fonoaudiólogo...', style: TextStyle(color: Colors.grey)));
  }
}
