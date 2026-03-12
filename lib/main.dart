// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'services/gamification_service.dart';
import 'services/profile_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar serviços
  final authService = AuthService();
  await authService.init();

  final profileService = ProfileService();
  await profileService.init();

  runApp(const ComunicaTeaApp());
}

class ComunicaTeaApp extends StatelessWidget {
  const ComunicaTeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COMUNICA-TEA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: FutureBuilder(
        future: _checkAuthentication(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Se snapshot.hasData for true, vai para Home
          // Se não, vai para Login
          return snapshot.data ?? const LoginScreen();
        },
      ),
    );
  }

  Future<Widget?> _checkAuthentication() async {
    final authService = AuthService();
    await authService.init();

    print('🔍 Verificando autenticação...');
    print('👤 Usuário atual: ${authService.currentUser?.username}');
    print('📊 Está logado: ${authService.isLoggedIn}');

    if (authService.isLoggedIn) {
      print('✅ Usuário logado! Indo para Home');

      // Se estiver logado e for criança, carregar progresso
      if (authService.isChild) {
        final childProfileId = authService.currentUser?.childProfileId;
        if (childProfileId != null) {
          await GamificationService().loadProgressForProfile(childProfileId);
        }
      }
      return const HomeScreen();
    }

    print('❌ Nenhum usuário logado. Indo para Login');
    return null; // null faz o builder mostrar LoginScreen
  }
}