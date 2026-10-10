import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/communication_log_model.dart';

class CommunicationLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveLog(CommunicationLog log) async {
    try {
      await _firestore
          .collection('children')
          .doc(log.childId)
          .collection('communication_logs')
          .doc(log.id)
          .set(log.toMap());
    } catch (e) {
      debugPrint('Erro ao salvar log de comunicação: $e');
    }
  }

  Future<List<CommunicationLog>> getLogs(String childId) async {
    try {
      final snapshot = await _firestore
          .collection('children')
          .doc(childId)
          .collection('communication_logs')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => CommunicationLog.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Erro ao buscar logs de comunicação: $e');
      return [];
    }
  }
}
