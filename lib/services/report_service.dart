import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> sendReportToParent(String childId, Map<String, dynamic> reportData) async {
    try {
      debugPrint('📡 ReportService: Tentando enviar relatório para ChildId: $childId');
      debugPrint('📦 Dados do relatório: $reportData');

      await _firestore.collection('reports').doc(childId).set({
        'childId': childId,
        'message': reportData['message'] ?? 'Sem mensagem',
        'highlight': reportData['highlight'] ?? 'Sem destaque',
        'home_activity': reportData['home_activity'] ?? 'Sem atividade',
        'word_of_the_week': reportData['word_of_the_week'] ?? 'Sem palavra',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ ReportService: Relatório gravado com sucesso no Firestore!');
      return true;
    } catch (e) {
      debugPrint('❌ ReportService: Erro ao enviar relatório: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getLatestReport(String childId) async {
    try {
      debugPrint('📡 ReportService: Buscando relatório para ChildId: $childId');
      final doc = await _firestore.collection('reports').doc(childId).get();
      
      if (doc.exists) {
        debugPrint('✅ ReportService: Relatório encontrado!');
        return doc.data();
      } else {
        debugPrint('⚠️ ReportService: Nenhum documento encontrado para este ChildId.');
        return null;
      }
    } catch (e) {
      debugPrint('❌ ReportService: Erro ao buscar relatório: $e');
      return null;
    }
  }
}
