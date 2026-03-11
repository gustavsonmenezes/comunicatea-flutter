import 'package:flutter/material.dart';
import '../../models/achievement_model.dart';
import '../../services/gamification_service.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Acessa o serviço para obter a lista de conquistas e o progresso
    final gamificationService = GamificationService();
    final userProgress = gamificationService.progress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Conquistas'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Duas colunas
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8, // Deixa o card mais "alto"
          ),
          itemCount: appAchievements.length,
          itemBuilder: (context, index) {
            final achievement = appAchievements[index];
            final isUnlocked = userProgress.unlockedAchievementIds.contains(achievement.id);

            return AchievementCard(achievement: achievement, isUnlocked: isUnlocked);
          },
        ),
      ),
    );
  }
}

// Widget para o Card de Conquista
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;

  const AchievementCard({super.key, required this.achievement, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked ? Theme.of(context).primaryColor : Colors.grey[300];
    final iconColor = isUnlocked ? Colors.white : Colors.grey[500];

    return Card(
      elevation: isUnlocked ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(achievement.icon, size: 50, color: iconColor),
            const SizedBox(height: 12),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.white : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isUnlocked ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
