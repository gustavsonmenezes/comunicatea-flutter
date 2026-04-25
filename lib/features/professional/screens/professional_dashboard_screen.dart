import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/professional_provider.dart';
import '../widgets/child_card.dart';
import 'child_details_screen.dart';
import '../../../models/child_profile.dart';
import '../../../models/profile_settings_model.dart';
import '../../../models/user_progress_model.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

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
            title: const Text('Painel do Profissional'),
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    provider.loadProfessionalData(user.uid);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await AuthService().logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
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
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
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
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildChildrenList(ProfessionalProvider provider, BuildContext context) {
    if (provider.children.isEmpty) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.child_care, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Nenhuma criança vinculada.', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                  builder: (context) => ChildDetailsScreen(child: child),
                ),
              );
            },
          );
        },
      ),
    );
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
          title: const Text('Cadastrar Nova Criança'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome da Criança'),
                ),
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(labelText: 'Idade'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: diagnosisController,
                  decoration: const InputDecoration(labelText: 'Diagnóstico (opcional)'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Senha de Acesso'),
                  obscureText: true,
                ),
                if (isSaving)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.isEmpty || passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nome e senha são obrigatórios')),
                        );
                        return;
                      }

                      setState(() => isSaving = true);

                      try {
                        final cleanName = nameController.text.toLowerCase().replaceAll(' ', '.');
                        final childEmail = '$cleanName.${DateTime.now().millisecondsSinceEpoch}@crianca.com';

                        final authService = AuthService();
                        final userCredential = await authService.registerChild(
                          childEmail,
                          passwordController.text,
                          nameController.text,
                        );

                        if (userCredential != null) {
                          final childUid = userCredential.user!.uid;

                          final newChild = ChildProfile(
                            id: childUid,
                            name: nameController.text,
                            age: int.tryParse(ageController.text) ?? 0,
                            diagnosis: diagnosisController.text,
                            professionalIds: [FirebaseAuth.instance.currentUser!.uid],
                            professionalEmails: [FirebaseAuth.instance.currentUser!.email ?? ''],
                            settings: ProfileSettings(),
                            progress: UserProgress(userId: childUid),
                            createdAt: DateTime.now(),
                            lastActive: DateTime.now(),
                          );

                          await provider.addChild(newChild);

                          if (context.mounted) {
                            Navigator.pop(context);
                            _showCredentialsDialog(
                                context, childEmail, passwordController.text, nameController.text);
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                        }
                      } finally {
                        if (mounted) setState(() => isSaving = false);
                      }
                    },
              child: const Text('Criar Criança'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCredentialsDialog(BuildContext context, String email, String password, String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Conta Criada com Sucesso!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passe estas credenciais para os responsáveis de $name:'),
            const SizedBox(height: 16),
            SelectableText('E-mail: $email', style: const TextStyle(fontWeight: FontWeight.bold)),
            SelectableText('Senha: $password', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'A criança deve usar estes dados para logar no aplicativo.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
