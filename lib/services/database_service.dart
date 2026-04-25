import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_profile.dart';
import '../models/user_progress_model.dart';

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
    String path = join(await getDatabasesPath(), 'comunica_tea_v3.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE children(id TEXT PRIMARY KEY, name TEXT, email TEXT, age INTEGER, diagnosis TEXT, photoUrl TEXT, professionalIds TEXT, professionalEmails TEXT, lastActive TEXT, createdAt TEXT, settings TEXT, progress TEXT)',
        );
      },
    );
  }

  Future<void> updateChildProgress(String childId, UserProgress progress) async {
    if (kIsWeb) {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .update({
            'progress': progress.toJson(),
            'lastActive': FieldValue.serverTimestamp()
          });
      return;
    }
    final db = await database;
    if (db != null) {
      await db.update(
        'children', 
        {'progress': jsonEncode(progress.toJson()), 'lastActive': DateTime.now().toIso8601String()},
        where: 'id = ?', 
        whereArgs: [childId]
      );
    }
  }

  Future<void> syncChildToCloud(ChildProfile child) async {
    await FirebaseFirestore.instance
        .collection('children')
        .doc(child.id)
        .set(child.toJson(), SetOptions(merge: true));
  }

  // ✅ Método adicionado para resolver erro no SpeechLogService
  Future<void> syncSpeechLogToCloud(Map<String, dynamic> logData) async {
    try {
      final String logId = logData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      await FirebaseFirestore.instance
          .collection('speech_logs')
          .doc(logId)
          .set(logData, SetOptions(merge: true));
    } catch (e) {
      print('Erro ao sincronizar log de fala: $e');
    }
  }

  Stream<List<ChildProfile>> getChildrenStreamByProfessional(String? email) {
    if (email == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('children')
        .where('professionalEmails', arrayContains: email)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChildProfile.fromJson(doc.data()))
            .toList());
  }

  Future<List<ChildProfile>> getChildrenByProfessional(String professionalId) async {
    if (kIsWeb) {
      final snapshot = await FirebaseFirestore.instance
          .collection('children')
          .where('professionalIds', arrayContains: professionalId)
          .get();
      return snapshot.docs
          .map((doc) => ChildProfile.fromJson(doc.data()))
          .toList();
    }
    final db = await database;
    if (db == null) return [];
    final maps = await db.query('children');
    return maps.map((map) {
      return ChildProfile.fromJson(map);
    }).toList();
  }

  Future<void> saveChild(ChildProfile child) async {
    await syncChildToCloud(child);

    if (!kIsWeb) {
      final db = await database;
      if (db != null) {
        final Map<String, dynamic> row = child.toJson();
        row['professionalIds'] = jsonEncode(row['professionalIds']);
        row['professionalEmails'] = jsonEncode(row['professionalEmails']);
        row['settings'] = jsonEncode(row['settings']);
        row['progress'] = jsonEncode(row['progress']);
        
        await db.insert('children', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }
}
