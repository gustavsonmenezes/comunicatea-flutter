class UserProgress {
  int totalStars;
  List<String> unlockedAchievementIds;
  Map<String, int> categoryUsage;

  UserProgress({
    this.totalStars = 0,
    this.unlockedAchievementIds = const [],
    this.categoryUsage = const {},
  });

  // Para salvar no SharedPreferences
  Map<String, dynamic> toJson() => {
    'totalStars': totalStars,
    'unlockedAchievementIds': unlockedAchievementIds,
    'categoryUsage': categoryUsage,
  };

  // Para carregar do SharedPreferences
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalStars: json['totalStars'] ?? 0,
      unlockedAchievementIds: List<String>.from(json['unlockedAchievementIds'] ?? []),
      categoryUsage: Map<String, int>.from(json['categoryUsage'] ?? {}),
    );
  }
}
