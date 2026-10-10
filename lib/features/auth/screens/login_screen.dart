import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';
import '../../communication/communication_screen.dart';
import '../../professional/screens/professional_dashboard_screen.dart';
import '../../settings/parent_dashboard_screen.dart';
import '../../../models/child_profile.dart';
import '../../../models/profile_settings_model.dart';
import '../../../models/user_progress_model.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      if (success) {
        final user = authService.currentUser;
        if (user != null) {
          final userType = await authService.getUserType(user.uid);
          
          if (mounted) {
            setState(() => _isLoading = false);
            
            if (userType == 'professional') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProfessionalDashboardScreen()),
              );
            } else if (userType == 'parent') {
              final childId = await authService.getParentChildId(user.uid);
              if (childId != null) {
                final child = ChildProfile(
                  id: childId, 
                  name: 'Carregando...', 
                  age: 0,
                  settings: ProfileSettings(),
                  progress: UserProgress(userId: childId),
                );
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => ParentDashboardScreen(child: child)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pai sem criança vinculada.'))
                );
              }
            } else if (userType == 'child') {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('currentChildId', user.uid);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const CommunicationScreen()),
              );
            } else {
              // Caso o tipo seja unknown ou não encontrado no Firestore
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro: Tipo de usuário não encontrado. Verifique se o cadastro foi concluído no banco de dados.'),
                  backgroundColor: Colors.red,
                ),
              );
              await authService.logout(); // Desloga para evitar loop
            }
          }
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail ou senha incorretos.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔥 O CUBO COLORIDO (Alusão ao Autismo e Neurodiversidade)
              _buildAutismCube(colorScheme),

              const SizedBox(height: 24),
              Text(
                'ComunicaTEA',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onBackground,
                  fontFamily: 'Quicksand',
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Dando voz à neurodiversidade',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onBackground.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Quicksand',
                ),
              ),
              const SizedBox(height: 48),

              // Campos de Entrada Soft UI
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Seu e-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Sua senha',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),

              // Botão de Login
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 4,
                    shadowColor: colorScheme.primary.withOpacity(0.4),
                  ),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ENTRAR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen())
                ),
                child: Text(
                  'Não tem uma conta? Criar conta',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Quicksand',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutismCube(ColorScheme colorScheme) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cubo Estilizado com cores do autismo
          Icon(Icons.view_in_ar_rounded, size: 64, color: colorScheme.primary),
          Positioned(
            right: 22,
            bottom: 22,
            child: Icon(Icons.extension_rounded, size: 24, color: Colors.amber[600]),
          ),
        ],
      ),
    );
  }
}
