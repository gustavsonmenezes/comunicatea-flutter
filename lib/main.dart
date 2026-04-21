import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/professional/screens/professional_dashboard_screen.dart';
import 'features/settings/speech_stats_screen.dart';

void main() async {
  // Garante que os bindings do Flutter estejam inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase
  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase inicializado com sucesso!");
  } catch (e) {
    debugPrint("❌ Erro ao inicializar o Firebase: $e");
  }

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
        '/professional-dashboard': (context) => const ProfessionalDashboardScreen(),
        '/speech_stats': (context) => const SpeechStatsScreen(),
      },
    );
  }
}