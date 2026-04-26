import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

class _ParentDashboardScreenState extends State<ParentDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();
  final StickerService _stickerService = StickerService();
  final SpeechLogService _logService = SpeechLogService();
  final TextEditingController _messageController = TextEditingController();
  
  bool _loading = true;
  bool _sendingMessage = false;
  Map<String, dynamic>? _parentReport;
  String _childName = "Carregando...";
  String _parentName = "Carregando...";
  List<StickerModel> _recentStickers = [];
  int _activeDaysThisWeek = 0;

  final Color _primaryPurple = const Color(0xFF6D28D9);
  final Color _bgGray = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final auth = AuthService();
      final pName = await auth.getUserName();

      final childDoc = await FirebaseFirestore.instance.collection('children').doc(widget.child.id).get();
      if (childDoc.exists && mounted) {
        setState(() {
          _childName = childDoc.data()?['name'] ?? "Criança";
          _parentName = pName;
        });
      }

      final report = await _reportService.getLatestReport(widget.child.id);
      final allStickers = await _stickerService.getStickers(widget.child.id);
      final unlockedStickers = allStickers.where((s) => s.isUnlocked).toList();
      final history = await _logService.getPerformanceHistory(widget.child.id);

      if (mounted) {
        setState(() {
          _parentReport = report;
          _recentStickers = unlockedStickers.reversed.take(4).toList();
          _activeDaysThisWeek = history.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 🔥 NOVA LÓGICA DE ENVIO (Coleção Independente)
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _sendingMessage = true);
    try {
      // 1. Salva na coleção global de mensagens para histórico
      await FirebaseFirestore.instance.collection('parent_messages').add({
        'childId': widget.child.id,
        'parentName': _parentName,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Atualiza o "último recado" no documento da criança para o fono ver fácil
      await FirebaseFirestore.instance.collection('children').doc(widget.child.id).set({
        'parentMessage': _messageController.text.trim(),
        'parentMessageAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensagem enviada com sucesso!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      debugPrint('Erro ao enviar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: Talvez você precise ajustar as regras do Firebase.'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
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
      backgroundColor: _bgGray,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Área da Família', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Responsável: $_parentName', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: _primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () => _showLogoutDialog()),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'ACOMPANHAMENTO'),
            Tab(text: 'COMUNICAÇÃO'),
          ],
        ),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildReportTab(),
              _buildMessageTab(),
            ],
          ),
    );
  }

  Widget _buildReportTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
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
            const SizedBox(height: 40),
            _buildUsageTip(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FALE COM O PROFISSIONAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('Use este espaço para contar como foi a semana em casa ou tirar dúvidas rápidas.', style: TextStyle(fontSize: 14, color: Colors.blueGrey)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.purple[100]!), boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.05), blurRadius: 10)]),
            child: TextField(
              controller: _messageController,
              maxLines: 10,
              decoration: const InputDecoration(hintText: 'Olá, gostaria de contar que...', border: InputBorder.none),
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _sendingMessage ? null : _sendMessage,
              icon: _sendingMessage ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
              label: const Text('ENVIAR MENSAGEM'),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoNote(),
        ],
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(Icons.info_outline, color: Colors.blue[800]),
        const SizedBox(width: 12),
        const Expanded(child: Text('Suas mensagens serão lidas pelo profissional durante a próxima análise clínica.', style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)))),
      ]),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Olá, família do $_childName! 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      const Text('Veja o que preparamos para vocês hoje.', style: TextStyle(fontSize: 14, color: Colors.blueGrey)),
    ]);
  }

  Widget _buildEngagementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blue[50]!), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle), child: Icon(Icons.auto_graph, color: Colors.blue[800])),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DEDICAÇÃO NA SEMANA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
          Text('$_activeDaysThisWeek de 7 dias praticando', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: _activeDaysThisWeek / 7, backgroundColor: Colors.blue[50], color: Colors.blue[400], minHeight: 6)),
        ])),
      ]),
    );
  }

  Widget _buildHighlightCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryPurple, const Color(0xFF8B5CF6)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _primaryPurple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.auto_awesome, color: Colors.white, size: 18), SizedBox(width: 8), Text('DESTAQUE DA SEMANA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))]),
        const SizedBox(height: 12),
        Text(_parentReport!['highlight'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_parentReport!['message'] ?? '', style: TextStyle(color: Colors.purple[50], fontSize: 14, height: 1.4)),
      ]),
    );
  }

  Widget _buildHomeActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.orange[50]!), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.home_rounded, color: Colors.orange[800], size: 20), const SizedBox(width: 8), const Text('ATIVIDADE PARA CASA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 11))]),
        const SizedBox(height: 12),
        Text(_parentReport!['home_activity'] ?? '', style: const TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.5)),
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
          Text(_parentReport!['word_of_the_week'] ?? '-', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF))),
        ])),
        Icon(Icons.record_voice_over_rounded, color: Colors.blue[300], size: 48),
      ]),
    );
  }

  Widget _buildStickersMural() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CONQUISTAS RECENTES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
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
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                  child: Center(child: Image.asset(sticker.imagePath, width: 50)),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildUsageTip() {
    return const Center(child: Text('O apoio da família é fundamental para o progresso.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)));
  }

  Widget _buildEmptyState() {
    return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Aguardando relatório do fonoaudiólogo...', style: TextStyle(color: Colors.grey))));
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deseja sair?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(onPressed: _handleLogout, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('SAIR')),
        ],
      ),
    );
  }
}
