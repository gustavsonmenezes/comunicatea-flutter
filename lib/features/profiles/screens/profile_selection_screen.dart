// features/profiles/screens/profile_selection_screen.dart
import 'package:flutter/material.dart';
import '../../../services/profile_service.dart';
import '../../../theme/app_theme.dart';
import 'create_profile_screen.dart';
import '../../communication/communication_screen.dart';
import '../widgets/profile_avatar.dart';
import '../models/profile_model.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _profileService.addListener(_onProfilesChanged);
  }

  void _onProfilesChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _profileService.removeListener(_onProfilesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESCOLHA SEU PERFIL'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryLight,
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: _profileService.profiles.isEmpty
            ? _buildEmptyState()
            : _buildProfilesGrid(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhum perfil encontrado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Crie um perfil para começar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _navigateToCreateProfile,
            icon: const Icon(Icons.add),
            label: const Text('CRIAR PERFIL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilesGrid() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Text(
          'Quem está usando?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: _profileService.profiles.length + 1,
            itemBuilder: (context, index) {
              if (index == _profileService.profiles.length) {
                return _buildAddProfileCard();
              }

              final profile = _profileService.profiles[index];
              return _buildProfileCard(profile);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(UserProfile profile) {
    return GestureDetector(
      onTap: () async {
        final success = await _profileService.selectProfile(profile.id);
        if (success && mounted) {
          // Vai para tela de comunicação
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CommunicationScreen()),
          );
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ProfileAvatar(
                emoji: profile.avatarEmoji,
                size: 70,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              ),
              const SizedBox(height: 10),
              Text(
                profile.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              const SizedBox(height: 5),
              if (profile.lastUsed != null)
                Text(
                  _formatDate(profile.lastUsed!),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddProfileCard() {
    return GestureDetector(
      onTap: _navigateToCreateProfile,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'NOVO PERFIL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateProfileScreen(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'hoje';
    if (difference == 1) return 'ontem';
    if (difference < 7) return 'há $difference dias';
    return '${date.day}/${date.month}';
  }
}