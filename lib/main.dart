import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/communication/communication_screen.dart';
import 'features/professional/screens/professional_dashboard_screen.dart';
import 'features/settings/speech_stats_screen.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/gamification_service.dart';
import 'features/professional/providers/professional_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Erro Firebase: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
        ChangeNotifierProvider(create: (_) => GamificationService()),
        ChangeNotifierProvider(create: (_) => ProfessionalProvider()),
      ],
      child: const ComunicaTeaApp(),
    ),
  );
}

class ComunicaTeaApp extends StatelessWidget {
  const ComunicaTeaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COMUNICA-TEA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/communication': (context) => const CommunicationScreen(),
        '/professional-dashboard': (context) => const ProfessionalDashboardScreen(),
        '/speech_stats': (context) => const SpeechStatsScreen(),
      },
    );
  }
}
