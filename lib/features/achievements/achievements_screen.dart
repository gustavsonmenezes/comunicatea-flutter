// features/achievements/achievements_screen.dart
import 'package:flutter/material.dart';
import '../../services/gamification_service.dart';
import '../../models/achievement_model.dart';
import '../../models/user_progress_model.dart';
import '../../theme/app_theme.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final GamificationService _gamificationService = GamificationService();
  late UserProgress _progress;

  @override
  void initState() {
    super.initState();
    _progress = _gamificationService.progress;
    _gamificationService.addListener(_onProgressChanged);
  }

  void _onProgressChanged() {
    setState(() {
      _progress = _gamificationService.progress;
    });
  }

  @override
  void dispose() {
    _gamificationService.removeListener(_onProgressChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Conquistas'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${_progress.totalStars}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryLight,
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: appAchievements.length,
          itemBuilder: (context, index) {
            final achievement = appAchievements[index];
            final isUnlocked = _progress.unlockedAchievementIds.contains(achievement.id);

            double progress = 0.0;
            if (achievement.requiredStars > 0) {
              progress = (_progress.totalStars / achievement.requiredStars).clamp(0.0, 1.0);
            } else {
              progress = (_progress.categoryUsage.length / 6).clamp(0.0, 1.0);
            }

            return _buildAchievementCard(achievement, isUnlocked, progress);
          },
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked, double progress) {
    return Card(
      elevation: isUnlocked ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isUnlocked
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              achievement.color.withOpacity(0.2),
              achievement.color.withOpacity(0.05),
            ],
          )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? achievement.color.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement.icon,
                  size: 32,
                  color: isUnlocked ? achievement.color : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isUnlocked ? achievement.color : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 11,
                  color: isUnlocked ? Colors.grey[700] : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              if (isUnlocked)
                const Icon(Icons.check_circle, color: Colors.green, size: 24)
              else if (achievement.requiredStars > 0)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(achievement.color),
                      minHeight: 4,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_progress.totalStars}/${achievement.requiredStars}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(achievement.color),
                      minHeight: 4,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_progress.categoryUsage.length}/6',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}