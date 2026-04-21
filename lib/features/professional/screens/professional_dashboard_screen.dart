import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/professional_provider.dart';
import '../widgets/child_card.dart';
import 'child_details_screen.dart';
import '../../../models/child_profile.dart';
import '../../../models/profile_settings_model.dart';
import '../../../models/user_progress_model.dart';

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionalDashboardScreen> createState() => _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState extends State<ProfessionalDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ✅ Tenta carregar usando o UID primeiro
        context.read<ProfessionalProvider>().loadProfessionalData(user.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfessionalProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Painel Profissional', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.loadProfessionalData(FirebaseAuth.instance.currentUser?.uid ?? ''),
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              _buildStatsHeader(provider),
              _buildChildrenList(provider, context),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddChildDialog(context, provider),
            icon: const Icon(Icons.person_add),
            label: const Text('Nova Criança'),
            backgroundColor: Colors.blue[800],
          ),
        );
      },
    );
  }

  Widget _buildStatsHeader(ProfessionalProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(color: Colors.blue[800], borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
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
    return Column(children: [Icon(icon, color: Colors.white, size: 20), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)), Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70))]);
  }

  Widget _buildChildrenList(ProfessionalProvider provider, BuildContext context) {
    if (provider.children.isEmpty) return const Expanded(child: Center(child: Text('Nenhuma criança vinculada.')));
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: provider.children.length,
        itemBuilder: (context, index) {
          final child = provider.children[index];
          return ChildCard(child: child, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildDetailsScreen(childId: child.id))));
        },
      ),
    );
  }

  void _showAddChildDialog(BuildContext context, ProfessionalProvider provider) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Adicionar Nova Criança'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome *')),
            TextField(controller: ageController, decoration: const InputDecoration(labelText: 'Idade *'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              final childId = 'child_${DateTime.now().millisecondsSinceEpoch}';
              final newChild = ChildProfile(
                id: childId,
                name: nameController.text,
                age: int.tryParse(ageController.text) ?? 0,
                // ✅ VINCULA TANTO O UID QUANTO O E-MAIL PARA GARANTIR A WEB
                professionalIds: [user.uid, user.email ?? ''],
                settings: ProfileSettings(voiceRate: 0.5, voicePitch: 1.0, highContrast: false, selectedVoice: 'pt-BR'),
                progress: UserProgress(userId: childId, totalSessions: 0, totalPhrasesBuilt: 0, activeDays: [], pictogramUsage: {}),
                lastActive: DateTime.now(),
                createdAt: DateTime.now(),
              );

              await provider.addChild(newChild);
              if (mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}