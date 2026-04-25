import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';
import '../models/speech_log_model.dart';

class SpeechLogService {
  static final SpeechLogService _instance = SpeechLogService._internal();
  factory SpeechLogService() => _instance;
  SpeechLogService._internal();

  final DatabaseService _dbService = DatabaseService();

  Future<void> _ensureTableExists() async {
    try {
      final db = await _dbService.database;
      if (db == null) return;

      // Cria a tabela se não existir
      await db.execute('''
        CREATE TABLE IF NOT EXISTS speech_logs(
          id TEXT PRIMARY KEY,
          childId TEXT,
          pictogram_id TEXT NOT NULL,
          target_word TEXT NOT NULL,
          recognized_words TEXT,
          is_success INTEGER NOT NULL,
          confidence REAL,
          timestamp TEXT NOT NULL
        )
      ''');

      // 🔥 FORÇA A ADIÇÃO DA COLUNA childId CASO ELA NÃO EXISTA (Migração manual)
      try {
        await db.execute('ALTER TABLE speech_logs ADD COLUMN childId TEXT');
      } catch (e) {
        // Se a coluna já existir, ele cai aqui e ignoramos o erro
      }
    } catch (e) {
      debugPrint('Erro ao verificar tabela speech_logs: $e');
    }
  }

  Future<void> saveLog(SpeechLog log) async {
    // 1. Tenta salvar na nuvem primeiro (Garante o monitoramento do profissional)
    try {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(log.childId)
          .collection('speech_logs')
          .doc(log.id)
          .set(log.toMap());
      debugPrint('✅ Log sincronizado na nuvem: ${log.targetWord}');
    } catch (e) {
      debugPrint('⚠️ Erro ao sincronizar nuvem (offline?): $e');
    }

    // 2. Tenta salvar localmente
    try {
      await _ensureTableExists();
      final db = await _dbService.database;
      if (db != null) {
        await db.insert(
          'speech_logs',
          log.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar log no SQLite: $e');
    }
  }

  Future<Map<String, dynamic>> getChildStatistics(String childId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .collection('speech_logs')
          .get();

      if (snapshot.docs.isEmpty) {
        return {'first_word': '-', 'easiest_word': '-', 'hardest_word': '-', 'total_attempts': 0, 'word_stats': []};
      }

      List<SpeechLog> logs = snapshot.docs.map((doc) => SpeechLog.fromMap(doc.data())).toList();
      
      Map<String, List<SpeechLog>> groupedLogs = {};
      for (var log in logs) {
        groupedLogs.putIfAbsent(log.targetWord, () => []).add(log);
      }

      List<Map<String, dynamic>> wordStats = [];
      String easiest = '-';
      String hardest = '-';
      double maxSuccess = -1;
      double minSuccess = 2;

      groupedLogs.forEach((word, wordLogs) {
        int successes = wordLogs.where((l) => l.isSuccess).length;
        double rate = successes / wordLogs.length;
        double avgConfidence = wordLogs.map((l) => l.confidence).reduce((a, b) => a + b) / wordLogs.length;

        wordStats.add({
          'word': word,
          'success_rate': rate,
          'attempts': wordLogs.length,
          'avg_confidence': avgConfidence,
        });

        if (rate > maxSuccess) {
          maxSuccess = rate;
          easiest = word;
        }
        if (rate < minSuccess) {
          minSuccess = rate;
          hardest = word;
        }
      });

      wordStats.sort((a, b) => b['success_rate'].compareTo(a['success_rate']));
      logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return {
        'first_word': logs.first.targetWord,
        'easiest_word': easiest,
        'hardest_word': hardest,
        'total_attempts': logs.length,
        'word_stats': wordStats,
        'recent_logs': logs.reversed.take(15).toList(),
      };
    } catch (e) {
      debugPrint('Erro ao buscar estatísticas: $e');
      return {'first_word': 'Erro', 'easiest_word': '-', 'hardest_word': '-', 'total_attempts': 0, 'word_stats': []};
    }
  }
}
