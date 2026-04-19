import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/child_profile.dart';
import '../models/user_progress_model.dart';
import '../models/profile_settings_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'comunica_tea.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de crianças
    await db.execute('''
      CREATE TABLE children(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER,
        diagnosis TEXT,
        photoUrl TEXT,
        responsibleId TEXT,
        lastActive TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Tabela de relação profissional-criança
    await db.execute('''
      CREATE TABLE professional_children(
        professionalId TEXT NOT NULL,
        childId TEXT NOT NULL,
        PRIMARY KEY (professionalId, childId),
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');

    // Tabela de progresso
    await db.execute('''
      CREATE TABLE progress(
        childId TEXT PRIMARY KEY,
        totalSessions INTEGER DEFAULT 0,
        totalPhrasesBuilt INTEGER DEFAULT 0,
        pictogramUsage TEXT,
        activeDays TEXT,
        recentSessions TEXT,
        totalStars INTEGER DEFAULT 0,
        categoryUsage TEXT,
        unlockedAchievementIds TEXT,
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');

    // Tabela de configurações
    await db.execute('''
      CREATE TABLE settings(
        childId TEXT PRIMARY KEY,
        voiceRate REAL DEFAULT 0.5,
        voicePitch REAL DEFAULT 1.0,
        highContrast INTEGER DEFAULT 0,
        selectedVoice TEXT DEFAULT 'pt-br-x-abd-local',
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');

    // 🔽 TABELA DE LOGS DE FALA 🔽
    await db.execute('''
      CREATE TABLE speech_logs(
        id TEXT PRIMARY KEY,
        pictogram_id TEXT NOT NULL,
        target_word TEXT NOT NULL,
        recognized_words TEXT,
        is_success INTEGER NOT NULL,
        confidence REAL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Atualizando banco de dados de versão $oldVersion para $newVersion');

    if (oldVersion < 2) {
      debugPrint('➕ Criando tabela speech_logs');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS speech_logs(
          id TEXT PRIMARY KEY,
          pictogram_id TEXT NOT NULL,
          target_word TEXT NOT NULL,
          recognized_words TEXT,
          is_success INTEGER NOT NULL,
          confidence REAL,
          timestamp TEXT NOT NULL
        )
      ''');
    }
  }

  // ==================== MÉTODOS PRINCIPAIS ====================

  // Salvar criança completa
  Future<void> saveChild(ChildProfile child) async {
    final db = await database;

    await db.transaction((txn) async {
      // Salvar dados básicos
      await txn.insert('children', {
        'id': child.id,
        'name': child.name,
        'age': child.age,
        'diagnosis': child.diagnosis,
        'photoUrl': child.photoUrl,
        'responsibleId': child.responsibleId,
        'lastActive': child.lastActive.toIso8601String(),
        'createdAt': child.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Salvar progresso
      await txn.insert('progress', {
        'childId': child.id,
        'totalSessions': child.progress.totalSessions,
        'totalPhrasesBuilt': child.progress.totalPhrasesBuilt,
        'pictogramUsage': jsonEncode(child.progress.pictogramUsage),
        'activeDays': jsonEncode(child.progress.activeDays.map((d) => d.toIso8601String()).toList()),
        'recentSessions': jsonEncode(child.progress.recentSessions.map((s) => s.toJson()).toList()),
        'totalStars': child.progress.totalStars,
        'categoryUsage': jsonEncode(child.progress.categoryUsage),
        'unlockedAchievementIds': jsonEncode(child.progress.unlockedAchievementIds),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Salvar configurações
      await txn.insert('settings', {
        'childId': child.id,
        'voiceRate': child.settings.voiceRate,
        'voicePitch': child.settings.voicePitch,
        'highContrast': child.settings.highContrast ? 1 : 0,
        'selectedVoice': child.settings.selectedVoice,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Salvar relações com profissionais
      for (String profId in child.professionalIds) {
        await txn.insert('professional_children', {
          'professionalId': profId,
          'childId': child.id,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    // Sincronizar com o Firestore
    await syncChildToCloud(child);
  }

  // Sincronizar criança com o Firestore
  Future<void> syncChildToCloud(ChildProfile child) async {
    try {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(child.id) // Usa o mesmo ID do SQLite
          .set(child.toMap(), SetOptions(merge: true));
      debugPrint("✅ Dados sincronizados com a nuvem!");
    } catch (e) {
      debugPrint("❌ Erro ao sincronizar: $e");
    }
  }

  // Buscar crianças de um profissional
  Future<List<ChildProfile>> getChildrenByProfessional(String professionalId) async {
    final db = await database;

    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT c.*, p.*, s.*
      FROM children c
      INNER JOIN professional_children pc ON c.id = pc.childId
      LEFT JOIN progress p ON c.id = p.childId
      LEFT JOIN settings s ON c.id = s.childId
      WHERE pc.professionalId = ?
      ORDER BY c.lastActive DESC
    ''', [professionalId]);

    List<ChildProfile> children = [];
    for (var row in rows) {
      try {
        // Converter valores com segurança
        String? pictogramUsageStr = row['pictogramUsage'] as String?;
        String? activeDaysStr = row['activeDays'] as String?;
        String? recentSessionsStr = row['recentSessions'] as String?;
        String? categoryUsageStr = row['categoryUsage'] as String?;
        String? unlockedAchievementIdsStr = row['unlockedAchievementIds'] as String?;

        // Reconstruir progresso
        UserProgress progress = UserProgress(
          userId: row['childId']?.toString() ?? '',
          totalSessions: (row['totalSessions'] as int?) ?? 0,
          totalPhrasesBuilt: (row['totalPhrasesBuilt'] as int?) ?? 0,
          pictogramUsage: pictogramUsageStr != null
              ? Map<String, int>.from(jsonDecode(pictogramUsageStr))
              : {},
          activeDays: activeDaysStr != null
              ? (jsonDecode(activeDaysStr) as List)
              .map((d) => DateTime.parse(d.toString()))
              .toList()
              : [],
          recentSessions: recentSessionsStr != null
              ? (jsonDecode(recentSessionsStr) as List)
              .map((s) => Session.fromJson(s as Map<String, dynamic>))
              .toList()
              : [],
          totalStars: (row['totalStars'] as int?) ?? 0,
          categoryUsage: categoryUsageStr != null
              ? Map<String, int>.from(jsonDecode(categoryUsageStr))
              : {},
          unlockedAchievementIds: unlockedAchievementIdsStr != null
              ? List<String>.from(jsonDecode(unlockedAchievementIdsStr))
              : [],
        );

        // Reconstruir configurações
        ProfileSettings settings = ProfileSettings(
          voiceRate: (row['voiceRate'] as num?)?.toDouble() ?? 0.5,
          voicePitch: (row['voicePitch'] as num?)?.toDouble() ?? 1.0,
          highContrast: (row['highContrast'] as int?) == 1,
          selectedVoice: row['selectedVoice']?.toString() ?? 'pt-br-x-abd-local',
        );

        // Reconstruir criança
        children.add(ChildProfile(
          id: row['id']?.toString() ?? '',
          name: row['name']?.toString() ?? '',
          age: row['age'] as int?,
          diagnosis: row['diagnosis']?.toString(),
          photoUrl: row['photoUrl']?.toString(),
          responsibleId: row['responsibleId']?.toString(),
          professionalIds: [],
          settings: settings,
          progress: progress,
          lastActive: DateTime.parse(
            row['lastActive']?.toString() ?? DateTime.now().toIso8601String(),
          ),
          createdAt: DateTime.parse(
            row['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
          ),
        ));
      } catch (e) {
        debugPrint('Erro ao processar criança: $e');
        continue;
      }
    }

    return children;
  }

  // Buscar uma criança específica
  Future<ChildProfile?> getChild(String childId) async {
    final db = await database;

    final rows = await db.rawQuery('''
      SELECT c.*, p.*, s.*
      FROM children c
      LEFT JOIN progress p ON c.id = p.childId
      LEFT JOIN settings s ON c.id = s.childId
      WHERE c.id = ?
    ''', [childId]);

    if (rows.isEmpty) return null;

    final row = rows.first;

    try {
      // Converter valores com segurança
      String? pictogramUsageStr = row['pictogramUsage'] as String?;
      String? activeDaysStr = row['activeDays'] as String?;
      String? recentSessionsStr = row['recentSessions'] as String?;
      String? categoryUsageStr = row['categoryUsage'] as String?;
      String? unlockedAchievementIdsStr = row['unlockedAchievementIds'] as String?;

      // Reconstruir progresso
      UserProgress progress = UserProgress(
        userId: row['childId']?.toString() ?? '',
        totalSessions: (row['totalSessions'] as int?) ?? 0,
        totalPhrasesBuilt: (row['totalPhrasesBuilt'] as int?) ?? 0,
        pictogramUsage: pictogramUsageStr != null
            ? Map<String, int>.from(jsonDecode(pictogramUsageStr))
            : {},
        activeDays: activeDaysStr != null
            ? (jsonDecode(activeDaysStr) as List)
            .map((d) => DateTime.parse(d.toString()))
            .toList()
            : [],
        recentSessions: recentSessionsStr != null
            ? (jsonDecode(recentSessionsStr) as List)
            .map((s) => Session.fromJson(s as Map<String, dynamic>))
            .toList()
            : [],
        totalStars: (row['totalStars'] as int?) ?? 0,
        categoryUsage: categoryUsageStr != null
            ? Map<String, int>.from(jsonDecode(categoryUsageStr))
            : {},
        unlockedAchievementIds: unlockedAchievementIdsStr != null
            ? List<String>.from(jsonDecode(unlockedAchievementIdsStr))
            : [],
      );

      ProfileSettings settings = ProfileSettings(
        voiceRate: (row['voiceRate'] as num?)?.toDouble() ?? 0.5,
        voicePitch: (row['voicePitch'] as num?)?.toDouble() ?? 1.0,
        highContrast: (row['highContrast'] as int?) == 1,
        selectedVoice: row['selectedVoice']?.toString() ?? 'pt-br-x-abd-local',
      );

      // Buscar profissionais associados
      final profRows = await db.query(
        'professional_children',
        where: 'childId = ?',
        whereArgs: [childId],
      );
      List<String> professionalIds = profRows
          .map((r) => r['professionalId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      return ChildProfile(
        id: row['id']?.toString() ?? '',
        name: row['name']?.toString() ?? '',
        age: row['age'] as int?,
        diagnosis: row['diagnosis']?.toString(),
        photoUrl: row['photoUrl']?.toString(),
        responsibleId: row['responsibleId']?.toString(),
        professionalIds: professionalIds,
        settings: settings,
        progress: progress,
        lastActive: DateTime.parse(
          row['lastActive']?.toString() ?? DateTime.now().toIso8601String(),
        ),
        createdAt: DateTime.parse(
          row['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao processar criança: $e');
      return null;
    }
  }

  // Atualizar progresso
  Future<void> updateChildProgress(String childId, UserProgress progress) async {
    final db = await database;
    await db.update('progress', {
      'totalSessions': progress.totalSessions,
      'totalPhrasesBuilt': progress.totalPhrasesBuilt,
      'pictogramUsage': jsonEncode(progress.pictogramUsage),
      'activeDays': jsonEncode(progress.activeDays.map((d) => d.toIso8601String()).toList()),
      'recentSessions': jsonEncode(progress.recentSessions.map((s) => s.toJson()).toList()),
      'totalStars': progress.totalStars,
      'categoryUsage': jsonEncode(progress.categoryUsage),
      'unlockedAchievementIds': jsonEncode(progress.unlockedAchievementIds),
    }, where: 'childId = ?', whereArgs: [childId]);

    await db.update('children', {
      'lastActive': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [childId]);
  }

  // Atualizar configurações
  Future<void> updateChildSettings(String childId, Map<String, dynamic> settings) async {
    final db = await database;

    Map<String, dynamic> updateData = {};

    if (settings.containsKey('voiceRate')) {
      updateData['voiceRate'] = settings['voiceRate'];
    }
    if (settings.containsKey('voicePitch')) {
      updateData['voicePitch'] = settings['voicePitch'];
    }
    if (settings.containsKey('highContrast')) {
      updateData['highContrast'] = settings['highContrast'] ? 1 : 0;
    }
    if (settings.containsKey('selectedVoice')) {
      updateData['selectedVoice'] = settings['selectedVoice'];
    }

    if (updateData.isNotEmpty) {
      await db.update(
        'settings',
        updateData,
        where: 'childId = ?',
        whereArgs: [childId],
      );
    }
  }

  // DELETAR CRIANÇA
  Future<void> deleteChild(String childId) async {
    final db = await database;
    await db.delete('children', where: 'id = ?', whereArgs: [childId]);
  }
}