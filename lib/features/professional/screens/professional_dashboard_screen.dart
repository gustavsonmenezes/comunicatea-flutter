import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/professional_provider.dart';
import 'child_details_screen.dart';
import '../../../models/child_profile.dart';
import '../../../models/profile_settings_model.dart';
import '../../../models/user_progress_model.dart';
import '../../../services/auth_service.dart';

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionalDashboardScreen> createState() => _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState extends State<ProfessionalDashboardScreen> {
  String _userName = "Carregando..."; // 🔥 NOVO

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final auth = AuthService();
    final name = await auth.getUserName();
    
    if (mounted) {
      setState(() => _userName = name);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<ProfessionalProvider>().loadProfessionalData(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfessionalProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Central de Monitoramento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Olá, $_userName', style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await AuthService().logout();
                  if (mounted) Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildStatsBanner(provider),
                    if (provider.totalAlerts > 0) _buildAlertBar(provider),
                    Expanded(child: _buildChildrenList(provider, context)),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddChildDialog(context, provider),
            icon: const Icon(Icons.person_add),
            label: const Text('Novo Aluno'),
            backgroundColor: Colors.blue[800],
          ),
        );
      },
    );
  }

  Widget _buildStatsBanner(ProfessionalProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statBox('ALUNOS', '${provider.totalChildren}', Icons.people_outline),
          _statBox('ATIVOS HOJE', '${provider.activeToday}', Icons.bolt),
          _statBox('ESTRELAS', _calculateTotalStars(provider.children), Icons.stars),
        ],
      ),
    );
  }

  String _calculateTotalStars(List<ChildProfile> children) {
    int total = 0;
    for (var child in children) {
      total += child.progress.totalStars;
    }
    return total.toString();
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAlertBar(ProfessionalProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${provider.totalAlerts} aluno(s) estão sem atividade há mais de 3 dias!',
              style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenList(ProfessionalProvider provider, BuildContext context) {
    if (provider.children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care, size: 80, color: Colors.grey[300]),
            const Text('Nenhum aluno cadastrado.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.children.length,
      itemBuilder: (context, index) {
        final child = provider.children[index];
        final bool isInactive = DateTime.now().difference(child.lastActive ?? DateTime.now()).inDays > 3;

        return Dismissible(
          key: Key(child.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red[400],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirmar Exclusão'),
                content: Text('Deseja realmente remover o aluno ${child.name} do sistema? Esta ação não pode ser desfeita.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true), 
                    child: const Text('DELETAR', style: TextStyle(color: Colors.red))
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            provider.deleteChild(child.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${child.name} removido do monitoramento')),
            );
          },
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isInactive ? Colors.red[100]! : Colors.transparent),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: isInactive ? Colors.red[100] : Colors.blue[100],
                child: Icon(Icons.person, color: isInactive ? Colors.red : Colors.blue[800]),
              ),
              title: Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('⭐ ${child.progress.totalStars} estrelas conquistadas'),
                  Text(
                    'Último acesso: ${_formatDate(child.lastActive)}',
                    style: TextStyle(fontSize: 12, color: isInactive ? Colors.red : Colors.grey),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChildDetailsScreen(child: child)),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Nunca';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddChildDialog(BuildContext context, ProfessionalProvider provider) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final diagnosisController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cadastrar Novo Aluno'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome')),
                TextField(controller: ageController, decoration: const InputDecoration(labelText: 'Idade'), keyboardType: TextInputType.number),
                TextField(controller: diagnosisController, decoration: const InputDecoration(labelText: 'Diagnóstico')),
                TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
                if (isSaving) const LinearProgressIndicator(),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                setState(() => isSaving = true);
                try {
                  final email = '${nameController.text.toLowerCase().replaceAll(' ', '.')}.${DateTime.now().millisecondsSinceEpoch}@crianca.com';
                  final auth = AuthService();
                  final cred = await auth.registerChild(email, passwordController.text, nameController.text);
                  if (cred != null) {
                    final newChild = ChildProfile(
                      id: cred.user!.uid,
                      name: nameController.text,
                      email: email,
                      age: int.tryParse(ageController.text) ?? 0,
                      diagnosis: diagnosisController.text,
                      professionalIds: [FirebaseAuth.instance.currentUser!.uid],
                      professionalEmails: [FirebaseAuth.instance.currentUser!.email ?? ''],
                      settings: ProfileSettings(),
                      progress: UserProgress(userId: cred.user!.uid),
                      lastActive: DateTime.now(),
                      createdAt: DateTime.now(),
                    );
                    await provider.addChild(newChild);
                    if (mounted) {
                      Navigator.pop(context);
                      _showCredentialsDialog(context, email, passwordController.text, nameController.text);
                    }
                  }
                } finally {
                  if (mounted) setState(() => isSaving = false);
                }
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCredentialsDialog(BuildContext context, String email, String password, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sucesso!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Conta para $name criada.'),
            const Divider(),
            SelectableText('E-mail: $email'),
            SelectableText('Senha: $password'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }
}
