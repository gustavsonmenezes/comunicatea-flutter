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
  String _userName = "Carregando...";
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final auth = AuthService();

    // Busca o nome do fono imediatamente
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
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ProfessionalProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildHeader(provider, colorScheme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MEUS ALUNOS',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: colorScheme.onBackground.withOpacity(0.5),
                          letterSpacing: 1.2,
                          fontFamily: 'Quicksand'
                        )
                      ),
                      Text('${provider.children.length} cadastrados',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Quicksand')
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.totalAlerts > 0) 
                SliverToBoxAdapter(child: _buildAlertBar(provider)),
              
              provider.isLoading
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                  : _buildChildrenList(provider, colorScheme),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddChildDialog(context, provider),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('NOVO ALUNO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 4,
          ),
        );
      },
    );
  }

  Widget _buildHeader(ProfessionalProvider provider, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: colorScheme.background,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.logout_rounded, color: colorScheme.onBackground),
          onPressed: () async {
            await AuthService().logout();
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.05),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CENTRAL CLÍNICA',
                  style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)
                ),
                Text('Olá, $_userName',
                  style: TextStyle(color: colorScheme.onBackground, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Quicksand')
                ),
                const Spacer(),
                // Bento Grid Stats
                Row(
                  children: [
                    Expanded(child: _bentoStat('ALUNOS', '${provider.totalChildren}', Icons.people_outline, colorScheme.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _bentoStat('HOJE', '${provider.activeToday}', Icons.bolt, colorScheme.secondary)),
                    const SizedBox(width: 12),
                    Expanded(child: _bentoStat('STARS', _calculateTotalStars(provider.children), Icons.stars_rounded, colorScheme.tertiary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bentoStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.w900, fontSize: 20, fontFamily: 'Quicksand')),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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

  Widget _buildAlertBar(ProfessionalProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${provider.totalAlerts} aluno(s) sem atividade há 3+ dias.',
              style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenList(ProfessionalProvider provider, ColorScheme colorScheme) {
    if (provider.children.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.child_care_rounded, size: 80, color: colorScheme.primary.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text('Nenhum aluno sob sua supervisão.',
                style: TextStyle(color: colorScheme.onBackground.withOpacity(0.4), fontFamily: 'Quicksand', fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final child = provider.children[index];
            final bool isInactive = DateTime.now().difference(child.lastActive ?? DateTime.now()).inDays > 3;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChildDetailsScreen(child: child))),
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isInactive ? colorScheme.error.withOpacity(0.5) : colorScheme.outline.withOpacity(0.1),
                      width: 1.5
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4)
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isInactive ? colorScheme.error.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: isInactive ? colorScheme.error : colorScheme.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(child.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF2D3436), fontFamily: 'Quicksand')
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _miniTag(Icons.stars_rounded, '${child.progress.totalStars}', Colors.amber[600]!),
                                const SizedBox(width: 8),
                                _miniTag(Icons.access_time_rounded, _formatDate(child.lastActive), isInactive ? colorScheme.error : Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: colorScheme.onBackground.withOpacity(0.3)),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: provider.children.length,
        ),
      ),
    );
  }

  Widget _miniTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold, fontFamily: 'Quicksand')),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Nunca';
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    return '${date.day}/${date.month}';
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Cadastrar Novo Aluno', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(nameController, 'Nome Completo', Icons.person_outline),
                _buildField(ageController, 'Idade', Icons.calendar_today_outlined, isNumeric: true),
                _buildField(diagnosisController, 'Diagnóstico', Icons.assignment_outlined),
                _buildField(passwordController, 'Senha de Acesso', Icons.lock_outline, isPassword: true),
                if (isSaving) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameController.text.isEmpty) return;
                setState(() => isSaving = true);
                try {
                  final String shortId = DateTime.now().millisecondsSinceEpoch.toString();
                  final email = '${nameController.text.toLowerCase().replaceAll(' ', '.')}.$shortId@crianca.com';
                  final auth = AuthService();
                  final cred = await auth.registerChild(email, passwordController.text, nameController.text);
                  if (cred != null) {
                    final newChild = ChildProfile(
                      id: cred.user!.uid,
                      shortId: shortId, // 🔥 Salva o código numérico
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: const Text('CADASTRAR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumeric = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _showCredentialsDialog(BuildContext context, String email, String password, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Conta Criada!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Use estes dados para entrar no perfil de $name:', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SelectableText('E-mail: $email', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  const Divider(),
                  SelectableText('Senha: $password', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ENTENDIDO'))],
      ),
    );
  }
}
