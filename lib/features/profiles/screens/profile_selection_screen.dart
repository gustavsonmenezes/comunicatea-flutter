import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/profile_service.dart';
import '../../../services/gamification_service.dart'; // ✅ ADICIONADO
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryLight, AppTheme.backgroundColor],
          ),
        ),
        child: _profileService.profiles.isEmpty
            ? _buildEmptyState()
            : _buildProfilesGrid(),
      ),
    );
  }

  Widget _buildProfilesGrid() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Text('Quem está usando?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1, crossAxisSpacing: 15, mainAxisSpacing: 15),
            itemCount: _profileService.profiles.length + 1,
            itemBuilder: (context, index) {
              if (index == _profileService.profiles.length) return _buildAddProfileCard();
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
          // ✅ VÍNCULO CRUCIAL: Avisa ao Gamification qual ID usar na nuvem
          // Se o perfil tiver um childId associado, usamos ele. Se não, usamos o próprio ID do perfil.
          final cloudId = profile.childId ?? profile.id;
          GamificationService().setCurrentChild(cloudId);
          await GamificationService().initializeForProfile(profile.id);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CommunicationScreen()),
          );
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfileAvatar(emoji: profile.avatarEmoji, size: 70),
            const SizedBox(height: 10),
            Text(profile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProfileCard() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProfileScreen())),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3), width: 2)),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 40, color: AppTheme.primaryColor),
            SizedBox(height: 10),
            Text('NOVO PERFIL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProfileScreen())),
        icon: const Icon(Icons.add),
        label: const Text('CRIAR PERFIL'),
      ),
    );
  }
}