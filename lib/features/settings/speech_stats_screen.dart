import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/speech_log_service.dart';
import '../../models/speech_log_model.dart';

class SpeechStatsScreen extends StatefulWidget {
  const SpeechStatsScreen({Key? key}) : super(key: key);

  @override
  _SpeechStatsScreenState createState() => _SpeechStatsScreenState();
}

class _SpeechStatsScreenState extends State<SpeechStatsScreen> {
  final SpeechLogService _logService = SpeechLogService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<SpeechLog> _recentLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _logService.getStatistics();
      final logs = await _logService.getAllLogs();
      setState(() {
        _stats = stats;
        _recentLogs = logs;
        _isLoading = false;
      });
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
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCards(),
              const SizedBox(height: 24),
              const Text(
                'Palavras Mais Praticadas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTopWordsList(),
              const SizedBox(height: 24),
              const Text(
                'Atividades Recentes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildRecentLogsList(),
              const SizedBox(height: 24),
              _buildWeeklyStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final totalAttempts = _stats['total_attempts'] ?? 0;
    final successRate = (_stats['success_rate'] ?? 0.0) * 100;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Tentativas',
            totalAttempts.toString(),
            Icons.mic,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Taxa de Sucesso',
            '${successRate.toStringAsFixed(1)}%',
            Icons.check_circle,
            _getSuccessRateColor(successRate),
          ),
        ),
      ],
    );
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 70) return Colors.green;
    if (rate >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopWordsList() {
    final List<dynamic> topWords = _stats['top_words'] ?? [];
    if (topWords.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Nenhuma palavra praticada ainda.\nToque em um pictograma e fale a palavra para começar!',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topWords.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final word = topWords[index];
          final count = word['count'] as int;
          final successCount = word['success_count'] as int;
          final rate = count > 0 ? successCount / count : 0.0;

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word['target_word'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$successCount acertos em $count tentativas',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: rate,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          rate >= 0.7 ? Colors.green : (rate >= 0.4 ? Colors.orange : Colors.red),
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(rate * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: rate >= 0.7 ? Colors.green : (rate >= 0.4 ? Colors.orange : Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentLogsList() {
    if (_recentLogs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Nenhuma atividade registrada ainda.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentLogs.length > 10 ? 10 : _recentLogs.length,
      itemBuilder: (context, index) {
        final log = _recentLogs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: log.isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                log.isSuccess ? Icons.check_circle : Icons.cancel,
                color: log.isSuccess ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              log.targetWord,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ouvido: "${log.recognizedWords}"'),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: log.confidence > 0
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: log.confidence > 0.7 ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(log.confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: log.confidence > 0.7 ? Colors.green : Colors.orange,
                ),
              ),
            )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildWeeklyStats() {
    final weeklyStats = _stats['weekly_stats'] as List<dynamic>? ?? [];
    if (weeklyStats.isEmpty) return const SizedBox.shrink();

    final days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final Map<int, Map<String, int>> weeklyData = {};

    for (var stat in weeklyStats) {
      final dayOfWeek = int.parse(stat['day_of_week'].toString());
      weeklyData[dayOfWeek] = {
        'attempts': stat['attempts'] as int,
        'successes': stat['successes'] as int,
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimos 7 Dias',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final data = weeklyData[index];
                final attempts = data?['attempts'] ?? 0;
                final successes = data?['successes'] ?? 0;
                final rate = attempts > 0 ? successes / attempts : 0.0;

                return Column(
                  children: [
                    Text(days[index], style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      width: 30,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (attempts > 0)
                            Container(
                              height: (rate * 50).clamp(0.0, 50.0),
                              width: 30,
                              decoration: BoxDecoration(
                                color: rate >= 0.7 ? Colors.green : (rate >= 0.4 ? Colors.orange : Colors.red),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$attempts',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}