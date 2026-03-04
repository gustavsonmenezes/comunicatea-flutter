import 'package:flutter/material.dart';
import '../communication/communication_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COMUNICA-TEA'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // Título
              const Text(
                'Bem-vindo ao',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.blueGrey,
                ),
              ),
              const Text(
                'COMUNICA-TEA',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),

              // Botão COMUNICAR (principal)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CommunicationScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(250, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'ENTRAR',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botão Configurações
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  minimumSize: const Size(250, 60),
                  side: BorderSide(color: Colors.blue.shade700, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'CONFIGURAÇÕES',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botão Sobre
              TextButton(
                onPressed: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'COMUNICA-TEA',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(
                      Icons.chat_bubble_outline,
                      size: 50,
                      color: Colors.blue,
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                            'Plataforma digital de Comunicação Aumentativa e Alternativa '
                                'para crianças com Transtorno do Espectro Autista.'
                        ),
                      ),
                    ],
                  );
                },
                child: const Text(
                  'Desenvolvido por Gustavson Barros',

                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}