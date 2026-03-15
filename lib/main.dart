import 'package:flutter/material.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/professional/screens/professional_dashboard_screen.dart'; // Nome corrigido

void main() {
  runApp(const ComunicaTeaApp());
}

class ComunicaTeaApp extends StatelessWidget {
  const ComunicaTeaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COMUNICA-TEA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/professional-dashboard': (context) => const ProfessionalDashboardScreen(), // Nome corrigido
      },
    );
  }
}