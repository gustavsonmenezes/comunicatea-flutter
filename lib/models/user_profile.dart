class UserProgress {
  final String userId;
  final int totalSessions;
  final int totalPhrasesBuilt;
  final Map<String, int> pictogramUsage;
  final List<DateTime> activeDays;
  final List<Session> recentSessions;

  UserProgress({
    required this.userId,
    this.totalSessions = 0,
    this.totalPhrasesBuilt = 0,
    this.pictogramUsage = const {},
    this.activeDays = const [],
    this.recentSessions = const [],
  });

  Map<DateTime, int> get weeklyUsage {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final Map<DateTime, int> usage = {};

    for (var session in recentSessions) {
      if (session.date.isAfter(weekAgo)) {
        final day = DateTime(session.date.year, session.date.month, session.date.day);
        usage[day] = (usage[day] ?? 0) + 1;
      }
    }

    return usage;
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'] ?? '',
      totalSessions: json['totalSessions'] ?? 0,
      totalPhrasesBuilt: json['totalPhrasesBuilt'] ?? 0,
      pictogramUsage: Map<String, int>.from(json['pictogramUsage'] ?? {}),
      activeDays: (json['activeDays'] as List?)
          ?.map((d) => DateTime.parse(d))
          .toList() ??
          [],
      recentSessions: (json['recentSessions'] as List?)
          ?.map((s) => Session.fromJson(s))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalSessions': totalSessions,
      'totalPhrasesBuilt': totalPhrasesBuilt,
      'pictogramUsage': pictogramUsage,
      'activeDays': activeDays.map((d) => d.toIso8601String()).toList(),
      'recentSessions': recentSessions.map((s) => s.toJson()).toList(),
    };
  }
}

class Session {
  final DateTime date;
  final int duration;
  final int phrasesCount;
  final List<String> usedPictograms;

  Session({
    required this.date,
    required this.duration,
    required this.phrasesCount,
    required this.usedPictograms,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      date: DateTime.parse(json['date']),
      duration: json['duration'],
      phrasesCount: json['phrasesCount'],
      usedPictograms: List<String>.from(json['usedPictograms'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'duration': duration,
      'phrasesCount': phrasesCount,
      'usedPictograms': usedPictograms,
    };
  }
}