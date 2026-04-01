import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
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
      debugPrint('✅ Tabela speech_logs verificada/criada');
    } catch (e) {
      debugPrint('❌ Erro ao criar tabela speech_logs: $e');
    }
  }

  Future<void> saveLog(SpeechLog log) async {
    try {
      await _ensureTableExists();
      final db = await _dbService.database;
      await db.insert(
        'speech_logs',
        log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ Log salvo: ${log.targetWord} - Sucesso: ${log.isSuccess}');
    } catch (e) {
      debugPrint('❌ Erro ao salvar log: $e');
    }
  }

  Future<List<SpeechLog>> getAllLogs() async {
    await _ensureTableExists();
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'speech_logs',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => SpeechLog.fromMap(maps[i]));
  }

  Future<List<SpeechLog>> getLogsByPictogram(String pictogramId) async {
    await _ensureTableExists();
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'speech_logs',
      where: 'pictogram_id = ?',
      whereArgs: [pictogramId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => SpeechLog.fromMap(maps[i]));
  }

  Future<Map<String, dynamic>> getStatistics() async {
    await _ensureTableExists();
    final db = await _dbService.database;

    final total = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM speech_logs')
    ) ?? 0;

    final successes = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM speech_logs WHERE is_success = 1')
    ) ?? 0;

    final List<Map<String, dynamic>> topWords = await db.rawQuery('''
      SELECT target_word, COUNT(*) as count, SUM(is_success) as success_count
      FROM speech_logs
      GROUP BY target_word
      ORDER BY count DESC
      LIMIT 5
    ''');

    final List<Map<String, dynamic>> weeklyStats = await db.rawQuery('''
      SELECT 
        strftime('%w', timestamp) as day_of_week,
        COUNT(*) as attempts,
        SUM(is_success) as successes
      FROM speech_logs
      WHERE timestamp >= datetime('now', '-7 days')
      GROUP BY day_of_week
      ORDER BY day_of_week
    ''');

    return {
      'total_attempts': total,
      'total_successes': successes,
      'success_rate': total > 0 ? (successes / total) : 0.0,
      'top_words': topWords,
      'weekly_stats': weeklyStats,
    };
  }

  Future<void> deleteAllLogs() async {
    await _ensureTableExists();
    final db = await _dbService.database;
    await db.delete('speech_logs');
    debugPrint('🗑️ Todos os logs de fala foram deletados');
  }

  Future<void> deleteOldLogs(DateTime beforeDate) async {
    await _ensureTableExists();
    final db = await _dbService.database;
    await db.delete(
      'speech_logs',
      where: 'timestamp < ?',
      whereArgs: [beforeDate.toIso8601String()],
    );
    debugPrint('🗑️ Logs anteriores a $beforeDate deletados');
  }
}