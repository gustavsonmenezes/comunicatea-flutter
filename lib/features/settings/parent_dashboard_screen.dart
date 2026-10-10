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

      // 1. Carrega o nome do Pai/Mãe IMEDIATAMENTE
      final pName = await auth.getUserName();
      if (mounted) {
        setState(() => _parentName = pName);
      }

      String resolvedChildId = widget.child.id;

      // 2. Resolve o ID caso seja o código curto numérico
      final isShortId = RegExp(r'^\d+$').hasMatch(resolvedChildId);
      if (isShortId) {
        debugPrint('🔍 ParentDashboard: Resolvendo código curto: $resolvedChildId');
        final childByShortId = await FirebaseFirestore.instance.collection('children')
            .where('shortId', isEqualTo: resolvedChildId).get();

        if (childByShortId.docs.isNotEmpty) {
          resolvedChildId = childByShortId.docs.first.id;
          debugPrint('🎯 ParentDashboard: Resolvido para UID: $resolvedChildId');
        }
      }

      // 3. Busca os dados da criança com o ID resolvido
      final childDoc = await FirebaseFirestore.instance.collection('children').doc(resolvedChildId).get();
      if (childDoc.exists && mounted) {
        setState(() {
          _childName = childDoc.data()?['name'] ?? "Criança";
        });
      } else if (mounted) {
        setState(() => _childName = "Meu Filho(a)");
      }

      // 4. Carrega o restante dos dados usando o ID RESOLVIDO
      final results = await Future.wait([
        _reportService.getLatestReport(resolvedChildId),
        _stickerService.getStickers(resolvedChildId),
        _logService.getPerformanceHistory(resolvedChildId),
      ]);

      if (mounted) {
        setState(() {
          _parentReport = results[0] as Map<String, dynamic>?;
          final allStickers = results[1] as List<StickerModel>;
          _recentStickers = allStickers.where((s) => s.isUnlocked).toList().reversed.take(4).toList();
          final history = results[2] as List<Map<String, dynamic>>;
          _activeDaysThisWeek = history.length;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar painel: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    setState(() => _sendingMessage = true);
    try {
      await FirebaseFirestore.instance.collection('parent_messages').add({
        'childId': widget.child.id,
        'parentName': _parentName,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('children').doc(widget.child.id).set({
        'parentMessage': _messageController.text.trim(),
        'parentMessageAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relato enviado para a clínica.'), backgroundColor: Colors.green)
        );
      }
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildSliverAppBar(colorScheme),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildAcompanhamentoTab(colorScheme),
                  _buildComunicacaoTab(colorScheme),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.background,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        centerTitle: false,
        title: Text('CENTRAL DA FAMÍLIA',
          style: TextStyle(color: colorScheme.onBackground, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Quicksand', letterSpacing: 1.2)
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colorScheme.error.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.power_settings_new_rounded, color: colorScheme.error, size: 20),
          ),
          onPressed: () => _showLogoutDialog(colorScheme),
        ),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
            labelColor: colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'Quicksand'),
            tabs: const [
              Tab(text: 'EVOLUÇÃO'),
              Tab(text: 'CONTATO'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcompanhamentoTab(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHero(colorScheme),
            const SizedBox(height: 24),
            _buildBentoGrid(colorScheme),
            const SizedBox(height: 24),
            if (_parentReport != null) ...[
              _buildReportHighlight(colorScheme),
              const SizedBox(height: 16),
              _buildHomeTaskCard(colorScheme),
            ] else 
              _buildEmptyReportCard(colorScheme),
            const SizedBox(height: 32),
            _buildStickersMural(colorScheme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHero(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.primary.withOpacity(0.2),
            child: Icon(Icons.family_restroom_rounded, color: colorScheme.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Olá, $_parentName',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colorScheme.onBackground, fontFamily: 'Quicksand')
                ),
                Text('Acompanhando o progresso de $_childName',
                  style: TextStyle(fontSize: 12, color: colorScheme.onBackground.withOpacity(0.6), fontWeight: FontWeight.w600)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _bentoItem(
                title: 'ATIVIDADE',
                value: '$_activeDaysThisWeek dias',
                subtitle: 'Esta semana',
                icon: Icons.calendar_today_rounded,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _bentoItem(
                title: 'STARS',
                value: '${widget.child.progress.totalStars}',
                icon: Icons.stars_rounded,
                color: Colors.amber[700]!,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_parentReport != null)
          _bentoItem(
            title: 'PALAVRA EM FOCO',
            value: _getDisplayValue(_parentReport!['word_of_the_week'], 'word') ?? '-',
            icon: Icons.record_voice_over_rounded,
            color: colorScheme.secondary,
            isFullWidth: true,
          ),
      ],
    );
  }

  Widget _bentoItem({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
              Icon(icon, size: 16, color: color.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: isFullWidth ? 28 : 22, fontWeight: FontWeight.w900, color: const Color(0xFF2D3436), fontFamily: 'Quicksand')),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          ]
        ],
      ),
    );
  }

  Widget _buildReportHighlight(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('DESTAQUE DA SEMANA', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5))
          ]),
          const SizedBox(height: 16),
          Text(_parentReport!['highlight'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Quicksand', height: 1.2)
          ),
          const SizedBox(height: 12),
          Text(_parentReport!['message'] ?? '',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, height: 1.6, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTaskCard(ColorScheme colorScheme) {
    final activity = _getDisplayValue(_parentReport!['home_activity'], 'description') ?? 'Nenhuma atividade registrada.';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.2), width: 2)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.home_work_rounded, color: colorScheme.onSecondary, size: 20),
            const SizedBox(width: 12),
            Text('TREINO EM CASA', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSecondary, fontSize: 10, letterSpacing: 1.2))
          ]),
          const SizedBox(height: 12),
          Text(activity,
            style: TextStyle(fontSize: 14, color: colorScheme.onSecondary.withOpacity(0.9), height: 1.6, fontWeight: FontWeight.w700, fontFamily: 'Quicksand')
          ),
        ],
      ),
    );
  }

  Widget _buildComunicacaoTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RELATO DA FAMÍLIA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2D3436), fontFamily: 'Quicksand')),
          const SizedBox(height: 8),
          const Text('Registre aqui observações, novas conquistas ou dificuldades percebidas em casa.', style: TextStyle(fontSize: 13, color: Colors.blueGrey, height: 1.5)),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)]
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: _messageController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'Escreva seu relato para o fonoaudiólogo...',
                      border: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                    style: const TextStyle(fontSize: 15, height: 1.6, fontFamily: 'Quicksand', fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28))
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _sendingMessage ? null : _sendMessage,
                    icon: _sendingMessage ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
                    label: const Text('ENVIAR RELATO CLÍNICO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildUsageInfo(colorScheme),
        ],
      ),
    );
  }

  Widget _buildUsageInfo(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          const Expanded(child: Text('Suas mensagens são criptografadas e visíveis apenas para o profissional responsável.', style: TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildStickersMural(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CONQUISTAS DE $_childName', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colorScheme.onBackground.withOpacity(0.5), letterSpacing: 1)),
        const SizedBox(height: 16),
        if (_recentStickers.isEmpty)
           _buildEmptyStickers(colorScheme)
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recentStickers.length,
              itemBuilder: (context, index) {
                final sticker = _recentStickers[index];
                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]
                  ),
                  child: Center(child: Padding(padding: const EdgeInsets.all(12), child: Image.asset(sticker.imagePath))),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyStickers(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Icon(Icons.emoji_events_outlined, color: colorScheme.outline.withOpacity(0.3), size: 40),
        const SizedBox(height: 12),
        const Text('O mural de conquistas está aguardando os primeiros treinos!', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildEmptyReportCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: colorScheme.outline.withOpacity(0.1))),
      child: Column(children: [
        Icon(Icons.hourglass_empty_rounded, size: 40, color: colorScheme.primary.withOpacity(0.3)),
        const SizedBox(height: 16),
        const Text('Aguardando a próxima análise clínica do fonoaudiólogo.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }

  String? _getDisplayValue(dynamic data, String field) {
    if (data == null) return null;
    if (data is Map) return data[field]?.toString() ?? data.values.first.toString();
    return data.toString();
  }

  void _showLogoutDialog(ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deseja sair?', style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Quicksand')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              await AuthService().logout();
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('SAIR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
