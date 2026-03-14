import 'package:flutter/material.dart';
import '../../../services/profile_service.dart';
import '../models/profile_model.dart';
import 'create_profile_screen.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});
  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final ProfileService _profileService = ProfileService();
  late Future<List<UserProfile>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _profilesFuture = _loadProfiles();
  }

  Future<List<UserProfile>> _loadProfiles() async {
    await _profileService.loadProfiles();
    return _profileService.profiles;
  }

  Future<void> _refreshProfiles() async {
    setState(() => _profilesFuture = _loadProfiles());
  }

  Future<void> _deleteProfile(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Perfil'),
        content: Text('Deseja excluir "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await _profileService.deleteProfile(id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name excluído!')));
      _refreshProfiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Perfis'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshProfiles)]),
      body: FutureBuilder<List<UserProfile>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.person_add, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Nenhum perfil criado', style: TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 8),
                Text('Crie o primeiro perfil para começar!', style: TextStyle(color: Colors.grey[600])),
              ]),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final profile = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor, child: Text(profile.avatarEmoji, style: const TextStyle(color: Colors.white, fontSize: 20))),
                  title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProfile(profile.id, profile.name),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProfileScreen())).then((_) => _refreshProfiles()),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
