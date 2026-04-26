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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos.')));
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
          // 🔥 BUSCA O TIPO DE USUÁRIO REAL
          final userType = await authService.getUserType(user.uid);
          
          if (mounted) {
            setState(() => _isLoading = false);
            
            debugPrint('🚀 Redirecionando usuário do tipo: $userType');

            if (userType == 'professional') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProfessionalDashboardScreen()),
              );
            } else if (userType == 'parent') {
              final childId = await authService.getParentChildId(user.uid);
              debugPrint('👨‍👩‍👦 Pai logado. ID da criança vinculada: $childId');
              
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pai sem criança vinculada.')));
              }
            } else if (userType == 'child') {
              // É uma criança
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('currentChildId', user.uid);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const CommunicationScreen()),
              );
            } else {
              // Caso não encontre (unknown)
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tipo de usuário não reconhecido.')));
            }
          }
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha no login.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 80, color: Colors.blue[800]),
              const SizedBox(height: 12),
              Text('COMUNICA-TEA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[800])),
              const SizedBox(height: 48),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ENTRAR'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
