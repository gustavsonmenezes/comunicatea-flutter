import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/professional_provider.dart';
import '../widgets/child_card.dart';
import 'child_details_screen.dart';
import '../../../models/child_profile.dart';
import '../../../models/profile_settings_model.dart';
import '../../../models/user_progress_model.dart';

class ProfessionalDashboardScreen extends StatelessWidget {
  const ProfessionalDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfessionalProvider()..loadProfessionalData('current_user_id'),
      child: Consumer<ProfessionalProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Painel Profissional',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                _buildNotificationIcon(context, provider),
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: () => provider.loadProfessionalData('current_user_id'),
              color: Colors.blue[800],
              child: Column(
                children: [
                  _buildStatsHeader(provider),
                  _buildChildrenList(provider, context),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddChildDialog(context, provider),
              icon: const Icon(Icons.person_add),
              label: const Text('Nova Criança'),
              backgroundColor: Colors.blue[800],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context, ProfessionalProvider provider) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showAlerts(context, provider.alerts),
        ),
        if (provider.alerts.isNotEmpty)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '${provider.alerts.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsHeader(ProfessionalProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Crianças', '${provider.totalChildren}', Icons.people),
          _buildStatItem('Ativas Hoje', '${provider.activeToday}', Icons.today),
          _buildStatItem('Alertas', '${provider.totalAlerts}', Icons.warning_amber),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenList(ProfessionalProvider provider, BuildContext context) {
    if (provider.children.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.child_care_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma criança cadastrada',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Toque no botão + para adicionar',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: provider.children.length,
        itemBuilder: (context, index) {
          final child = provider.children[index];
          return ChildCard(
            child: child,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChildDetailsScreen(childId: child.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAlerts(BuildContext context, List<Map<String, dynamic>> alerts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alertas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: alerts.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 48, color: Colors.green[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum alerta no momento!',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  Color alertColor = Colors.orange;
                  IconData alertIcon = Icons.warning;

                  if (alert['severity'] == 'high') {
                    alertColor = Colors.red;
                    alertIcon = Icons.error;
                  } else if (alert['severity'] == 'positive') {
                    alertColor = Colors.green;
                    alertIcon = Icons.emoji_events;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: alertColor.withOpacity(0.1),
                    child: ListTile(
                      leading: Icon(alertIcon, color: alertColor),
                      title: Text(
                        alert['childName'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(alert['message']),
                      trailing: Text(
                        _formatAlertDate(alert['date']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChildDialog(BuildContext context, ProfessionalProvider provider) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final diagnosisController = TextEditingController();
    bool isLoading = false;

    // Verifica se há profissional logado ANTES de abrir o diálogo
    if (provider.currentProfessional == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Profissional não está logado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Adicionar Nova Criança'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da criança *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(
                    labelText: 'Idade *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: diagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnóstico (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                ),
                if (isLoading) const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                  // Validações
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, insira o nome da criança'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final ageText = ageController.text.trim();
                  if (ageText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, insira a idade'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final age = int.tryParse(ageText);
                  if (age == null || age <= 0 || age > 18) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, insira uma idade válida (1-18)'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() => isLoading = true);

                  try {
                    final childId = DateTime.now().millisecondsSinceEpoch.toString();
                    final newChild = ChildProfile(
                      id: childId,
                      name: name,
                      age: age,
                      diagnosis: diagnosisController.text.trim().isEmpty
                          ? null
                          : diagnosisController.text.trim(),
                      photoUrl: null,
                      responsibleId: null,
                      professionalIds: [provider.currentProfessional!.id],
                      settings: ProfileSettings(
                        voiceRate: 0.5,
                        voicePitch: 1.0,
                        highContrast: false,
                        selectedVoice: 'pt-BR',
                      ),
                      progress: UserProgress(
                        userId: childId,
                        totalSessions: 0,
                        totalPhrasesBuilt: 0,
                        activeDays: [],
                        pictogramUsage: {},
                      ),
                      lastActive: DateTime.now(),
                      createdAt: DateTime.now(),
                    );

                    await provider.addChild(newChild);

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$name cadastrado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    setState(() => isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao cadastrar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Adicionar'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatAlertDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inHours;

    if (difference < 1) return 'Agora';
    if (difference < 24) return 'há $difference h';
    return '${date.day}/${date.month}';
  }
}