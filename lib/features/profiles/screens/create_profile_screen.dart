// features/profiles/screens/create_profile_screen.dart
import 'package:flutter/material.dart';
import '../../../services/profile_service.dart';
import '../../../theme/app_theme.dart';
import '../models/profile_model.dart';
import '../../communication/communication_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedAvatar = availableAvatars.first;
  bool _isLoading = false;

  final ProfileService _profileService = ProfileService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRIAR PERFIL'),
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 20),

              const Text(
                'Escolha um avatar e um nome',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              Container(
                width: 150,
                height: 150,
                margin: const EdgeInsets.symmetric(horizontal: 100),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    _selectedAvatar,
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Escolha um avatar:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                height: 120,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 1,
                  ),
                  itemCount: availableAvatars.length,
                  itemBuilder: (context, index) {
                    final emoji = availableAvatars[index];
                    final isSelected = emoji == _selectedAvatar;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatar = emoji;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withOpacity(0.3)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                            color: AppTheme.primaryColor,
                            width: 2,
                          )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: TextStyle(
                              fontSize: isSelected ? 35 : 30,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome da criança',
                  hintText: 'Ex: João, Maria, Ana...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um nome';
                  }
                  if (value.length < 2) {
                    return 'Nome muito curto';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _createProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CRIAR PERFIL E COMEÇAR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final success = await _profileService.createProfile(
        _nameController.text.trim(),
        _selectedAvatar,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        // Após criar, vai direto para comunicação
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CommunicationScreen(),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao criar perfil. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}