import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.isLoggedIn) {
      final user = authService.currentUser;
      if (user != null) {
        final userType = await authService.getUserType(user.uid);
        
        if (mounted) {
          if (userType == 'professional') {
            Navigator.of(context).pushReplacementNamed('/professional-dashboard');
          } else if (userType == 'parent') {
            // Para pais, como precisamos do objeto ChildProfile, melhor mandar para o login
            // ou buscar os dados aqui. Para simplificar e garantir segurança, mandamos para o login
            // se o estado não estiver claro.
            Navigator.of(context).pushReplacementNamed('/login');
          } else if (userType == 'child') {
            Navigator.of(context).pushReplacementNamed('/communication');
          } else {
            // Se for unknown, força o login
            Navigator.of(context).pushReplacementNamed('/login');
          }
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
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
                  Icon(Icons.view_in_ar_rounded, size: 80, color: colorScheme.primary),
                  Positioned(
                    right: 25,
                    bottom: 25,
                    child: Icon(Icons.extension_rounded, size: 30, color: Colors.amber[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'ComunicaTEA',
              style: TextStyle(
                color: colorScheme.onBackground,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
