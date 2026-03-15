// lib/features/home/home_screen.dart - VERSÃO FINAL CORRIGIDA PRONTA PARA COPIAR E COLAR
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../profiles/screens/profile_selection_screen.dart';
import '../profiles/screens/create_profile_screen.dart';
import '../profiles/screens/profile_management_screen.dart';
import '../settings/settings_screen.dart';
import '../achievements/achievements_screen.dart';
// import '../professional/professional_screen.dart'; // REMOVIDO
// import '../professional/screens/professional_dashboard_screen.dart'; // REMOVIDO
import '../stickers/screens/sticker_album_screen.dart';
import '../../models/pictogram_model.dart';
import '../memory_game/screens/memory_game_screen.dart';
import '../memory_game/models/pictogram_adapter.dart';

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

  void _navigateToMemoryGame(BuildContext context) {
    final categories = defaultPictogramCategories;

    if (categories.length > 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Escolha uma categoria'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  leading: Icon(category.icon, color: category.color),
                  title: Text(category.name),
                  onTap: () {
                    Navigator.pop(context);
                    final memoryPictograms = category.pictograms.map((p) {
                      return MemoryPictogram.fromCategory(category, p);
                    }).toList();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MemoryGameScreen(
                          category: category.name,
                          pictograms: memoryPictograms,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
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
          _buildDrawerTile(Icons.people, 'Gerenciar Perfis', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileManagementScreen(),
              ),
            );
          }),
          _buildDrawerTile(Icons.album, 'Meu Álbum', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StickerAlbumScreen()),
            );
          }),
          _buildDrawerTile(Icons.sports_esports, 'Jogo da Memória', () {
            Navigator.pop(context);
            _navigateToMemoryGame(context);
          }),
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
      width: double.maxFinite,
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
    return Column(
      children: [
        Row(
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
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                Icons.verified_user,
                'Profissional (TESTE)',
                    () => Navigator.pushNamed(context, '/professional-dashboard'),
              ),
            ),
          ],
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
    // CORRIGIDO - removido ProfessionalScreen inexistente
    _navigateToScreen(context, const ProfileSelectionScreen());
  }

  void _handleLogout() {
    AuthService().logout();
  }
}
