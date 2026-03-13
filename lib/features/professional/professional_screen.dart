// lib/features/professional/professional_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'professional_model.dart';
import '../../services/auth_service.dart';

class ProfessionalScreen extends StatelessWidget {
  const ProfessionalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final professional = authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.primaryLight,
      appBar: AppBar(
        title: Text('${professional?.displayName ?? "Profissional"}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // HEADER COM FOTO
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Text(
                professional?.displayName?.substring(0,1).toUpperCase() ?? 'P',
                style: const TextStyle(fontSize: 40, color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),

            // NOME E REGISTRO
            Text(
              professional?.displayName ?? "Dra. Maria Silva",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              "CRO #1234 | Fonoaudiologia",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            const SizedBox(height: 30),

            // CARDS DE MÉTRICAS
            Row(
              children: [
                Expanded(child: _buildMetricCard("⭐ HOJE", "28/50", Colors.amber)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard("👶 CRIANÇAS", "3", Colors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMetricCard("📈 SEMANA", "+23%", Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard("🎯 META", "50⭐", Colors.purple)),
              ],
            ),

            const Spacer(),

            // BOTÕES DE AÇÃO
            ElevatedButton.icon(
              onPressed: () => _showChildrenList(context),
              icon: const Icon(Icons.child_care),
              label: const Text("VER CRIANÇAS"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => AuthService().logout(),
              child: const Text("SAIR", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showChildrenList(BuildContext context) {
    // TODO: Integrar com ProfileService
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Lista de crianças em desenvolvimento!")),
    );
  }
}
