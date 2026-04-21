import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/child_profile.dart';
import '../models/user_progress_model.dart';
import '../models/profile_settings_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database?> _initDatabase() async {
    if (kIsWeb) return null;
    String path = join(await getDatabasesPath(), 'comunica_tea.db');
    return await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE children(id TEXT PRIMARY KEY, name TEXT NOT NULL, age INTEGER, diagnosis TEXT, photoUrl TEXT, responsibleId TEXT, lastActive TEXT NOT NULL, createdAt TEXT NOT NULL)');
    await db.execute('CREATE TABLE professional_children(professionalId TEXT NOT NULL, childId TEXT NOT NULL, PRIMARY KEY (professionalId, childId))');
    await db.execute('CREATE TABLE progress(childId TEXT PRIMARY KEY, totalSessions INTEGER DEFAULT 0, totalPhrasesBuilt INTEGER DEFAULT 0, pictogramUsage TEXT, activeDays TEXT, recentSessions TEXT, totalStars INTEGER DEFAULT 0, categoryUsage TEXT, unlockedAchievementIds TEXT)');
    await db.execute('CREATE TABLE settings(childId TEXT PRIMARY KEY, voiceRate REAL DEFAULT 0.5, voicePitch REAL DEFAULT 1.0, highContrast INTEGER DEFAULT 0, selectedVoice TEXT DEFAULT "pt-br-x-abd-local", FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE)');
    await db.execute('CREATE TABLE speech_logs(id TEXT PRIMARY KEY, pictogram_id TEXT NOT NULL, target_word TEXT NOT NULL, recognized_words TEXT, is_success INTEGER NOT NULL, confidence REAL, timestamp TEXT NOT NULL)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE IF NOT EXISTS speech_logs(id TEXT PRIMARY KEY, pictogram_id TEXT NOT NULL, target_word TEXT NOT NULL, recognized_words TEXT, is_success INTEGER NOT NULL, confidence REAL, timestamp TEXT NOT NULL)');
    }
  }

  // ==================== SINCRONIZAÇÃO ====================

  Future<void> syncProgressToCloud(String childId, Map<String, dynamic> progressData) async {
    try {
      await FirebaseFirestore.instance.collection('progress').doc(childId).set(progressData, SetOptions(merge: true));
      debugPrint("✅ CLOUD: Progresso enviado! Estrelas atuais: ${progressData['totalStars']}");
    } catch (e) {
      debugPrint("❌ CLOUD ERROR: Falha ao enviar progresso: $e");
    }
  }

  Future<void> syncChildToCloud(ChildProfile child) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      List<String> profIds = List.from(child.professionalIds);
      if (currentUser != null && !profIds.contains(currentUser.uid)) {
        profIds.add(currentUser.uid);
      }

      final data = child.toJson();
      data['professionalIds'] = profIds;

      await FirebaseFirestore.instance.collection('children').doc(child.id).set(data, SetOptions(merge: true));
      debugPrint("✅ CLOUD: Perfil de ${child.name} sincronizado.");
    } catch (e) {
      debugPrint("❌ CLOUD ERROR: Falha ao enviar perfil: $e");
    }
  }

  Future<void> syncSpeechLogToCloud(Map<String, dynamic> logData) async {
    try {
      await FirebaseFirestore.instance.collection('speech_logs').add(logData);
    } catch (e) {
      debugPrint("❌ CLOUD ERROR Log: $e");
    }
  }

  // ==================== BUSCA E STREAMS ====================

  Stream<List<ChildProfile>> getChildrenStreamByProfessional(String professionalId) {
    return FirebaseFirestore.instance
        .collection('children')
        .where('professionalIds', arrayContains: professionalId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<ChildProfile> children = [];
          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data();
            final progSnapshot = await FirebaseFirestore.instance.collection('progress').doc(doc.id).get();
            if (progSnapshot.exists) data['progress'] = progSnapshot.data();
            children.add(ChildProfile.fromJson(data));
          }
          return children;
        });
  }

  Future<List<ChildProfile>> getChildrenByProfessional(String professionalId) async {
    if (kIsWeb) {
      final snapshot = await FirebaseFirestore.instance.collection('children').where('professionalIds', arrayContains: professionalId).get();
      List<ChildProfile> children = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        final progSnapshot = await FirebaseFirestore.instance.collection('progress').doc(doc.id).get();
        if (progSnapshot.exists) data['progress'] = progSnapshot.data();
        children.add(ChildProfile.fromJson(data));
      }
      return children;
    }
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> rows = await db.rawQuery('SELECT c.*, p.*, s.* FROM children c INNER JOIN professional_children pc ON c.id = pc.childId LEFT JOIN progress p ON c.id = p.childId LEFT JOIN settings s ON c.id = s.childId WHERE pc.professionalId = ?', [professionalId]);
    
    List<ChildProfile> children = [];
    for (var row in rows) {
      children.add(_mapRowToChild(row, [professionalId]));
    }
    return children;
  }

  ChildProfile _mapRowToChild(Map<String, dynamic> row, List<String> professionalIds) {
    // Mapeamento completo para evitar erros de cast
    return ChildProfile(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      age: row['age'] as int?,
      diagnosis: row['diagnosis']?.toString(),
      professionalIds: professionalIds,
      settings: ProfileSettings(
        voiceRate: (row['voiceRate'] as num?)?.toDouble() ?? 0.5,
        voicePitch: (row['voicePitch'] as num?)?.toDouble() ?? 1.0,
        highContrast: (row['highContrast'] as int?) == 1,
        selectedVoice: row['selectedVoice']?.toString() ?? 'pt-BR',
      ),
      progress: UserProgress(
        userId: row['id']?.toString() ?? '',
        totalSessions: (row['totalSessions'] as int?) ?? 0,
        totalPhrasesBuilt: (row['totalPhrasesBuilt'] as int?) ?? 0,
        activeDays: [],
        pictogramUsage: {},
        totalStars: (row['totalStars'] as int?) ?? 0,
      ),
      lastActive: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  // ==================== OPERAÇÕES ====================

  Future<void> saveChild(ChildProfile child) async {
    if (!kIsWeb) {
      final db = await database;
      if (db != null) {
        await db.insert('children', {
          'id': child.id,
          'name': child.name,
          'age': child.age,
          'diagnosis': child.diagnosis,
          'lastActive': child.lastActive.toIso8601String(),
          'createdAt': child.createdAt.toIso8601String()
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        for (var profId in child.professionalIds) {
          await db.insert('professional_children', {'professionalId': profId, 'childId': child.id}, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    }
    await syncChildToCloud(child);
  }

  Future<void> updateChildProgress(String childId, UserProgress progress) async {
    if (!kIsWeb) {
      final db = await database;
      if (db != null) {
        await db.update('progress', {
          'totalStars': progress.totalStars,
          'totalPhrasesBuilt': progress.totalPhrasesBuilt
        }, where: 'childId = ?', whereArgs: [childId]);
      }
    }
    await syncProgressToCloud(childId, progress.toJson());
  }

  Future<void> updateChildSettings(String childId, Map<String, dynamic> settings) async {
    await FirebaseFirestore.instance.collection('children').doc(childId).update({'settings': settings});
  }

  Future<void> deleteChild(String childId) async {
    await FirebaseFirestore.instance.collection('children').doc(childId).delete();
  }

  Future<ChildProfile?> getChild(String childId) async {
    final doc = await FirebaseFirestore.instance.collection('children').doc(childId).get();
    if (!doc.exists) return null;
    return ChildProfile.fromJson(doc.data()!);
  }
}