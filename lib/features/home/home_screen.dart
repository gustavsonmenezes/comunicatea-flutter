// features/home/home_screen.dart - VERSÃO CORRIGIDA E FUNCIONANDO
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../profiles/screens/profile_selection_screen.dart';
import '../profiles/screens/create_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../achievements/achievements_screen.dart';
import '../professional/professional_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _navigateToCommunication(BuildContext context) async {
    final profileService = ProfileService();

    if (profileService.profiles.isEmpty) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
        );
      }
    } else {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'COMUNICA-TEA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, size: 28),
            onPressed: () => _navigateToScreen(context, const AchievementsScreen()),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildBody(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF4A90E2)),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _buildDrawerTile(Icons.home, 'Home', () => Navigator.pop(context)),
          _buildDrawerTile(Icons.person, 'Meu Perfil', () => _handleProfile(context)),
          _buildDrawerTile(Icons.settings, 'Configurações',
                  () => _navigateToScreen(context, const SettingsScreen())),
          _buildDrawerTile(Icons.emoji_events, 'Conquistas',
                  () => _navigateToScreen(context, const AchievementsScreen())),
          const Divider(),
          _buildDrawerTile(Icons.logout, 'Sair', _handleLogout, Colors.red),
        ],
      ),
    );
  }

  // ✅ CORRIGIDO: Parâmetro 'textColor' ao invés de 'color'
  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap, [Color? textColor]) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: textColor != null ? TextStyle(color: textColor) : null),
      onTap: onTap,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F9FF), Color(0xFFEFF2F8)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 32),
                    _buildWelcomeText(),
                    const SizedBox(height: 48),
                    _buildMainButton(context),
                    const SizedBox(height: 40),
                    _buildQuickActions(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            'assets/images/logocomunicatea.jpeg',
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: const Icon(
                Icons.chat,
                size: 60,
                color: Color(0xFF4A90E2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Column(
      children: [
        Text(
          'COMUNICA-TEA',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Treine sua comunicação agora!',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF7F8C8D),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: () => _navigateToCommunication(context),
        icon: const Icon(Icons.mic, size: 28),
        label: const Text(
          'INICIAR COMUNICAÇÃO',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _buildActionCard(
                context,
                Icons.emoji_events,
                'Conquistas',
                    () => _navigateToScreen(context, const AchievementsScreen())
            )
        ),
        const SizedBox(width: 16),
        Expanded(
            child: _buildActionCard(
                context,
                Icons.settings,
                'Configurações',
                    () => _navigateToScreen(context, const SettingsScreen())
            )
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AppTheme.primaryColor),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  void _handleProfile(BuildContext context) {
    Navigator.pop(context);
    final authService = AuthService();
    final screen = authService.isProfessional
        ? const ProfessionalScreen()
        : const ProfileSelectionScreen();
    _navigateToScreen(context, screen);
  }

  void _handleLogout() {
    AuthService().logout();
    // Navegação será tratada no widget pai ou via callback
  }
}
