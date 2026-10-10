import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/child_profile.dart';
import '../../models/profile_settings_model.dart';
import '../../models/user_progress_model.dart';
import 'parent_dashboard_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final childMock = ChildProfile(
      id: 'child123', 
      name: 'Joãozinho', 
      age: 5,
      diagnosis: 'TEA Nível 1',
      settings: ProfileSettings(),
      progress: UserProgress(userId: 'child123'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações', style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Quicksand')),
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader('ÁREA DA FAMÍLIA'),
          _buildSettingsTile(
            icon: Icons.family_restroom,
            title: 'Painel de Acompanhamento',
            subtitle: 'Progresso e atividades para casa',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ParentDashboardScreen(child: childMock)),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('OPÇÕES DO APLICATIVO'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Perfil do Aluno',
            color: Colors.blue,
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.volume_up_outlined,
            title: 'Configurações de Voz',
            color: Colors.teal,
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Modo Profissional (Senha)',
            color: Colors.orange,
            onTap: () {},
          ),
          const SizedBox(height: 32),
          const Divider(),
          _buildSettingsTile(
            icon: Icons.logout_rounded,
            title: 'Sair da Conta',
            subtitle: 'Voltar para a tela de login',
            color: colorScheme.error,
            onTap: () => _showLogoutDialog(context, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.grey,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Quicksand')),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deseja sair?', style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Quicksand')),
        content: const Text('Você precisará fazer login novamente para acessar seus dados.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('SAIR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
