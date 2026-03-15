import 'dart:io';
import 'package:flutter/material.dart';
import '../../../lib/models/child_profile.dart';

class ProfessionalService {

  // Futuramente: gerar relatórios em PDF
  Future<void> generatePdfReport(ChildProfile child) async {
    debugPrint('Gerando relatório para: ${child.name}');
    // Implementação futura
  }

  // Futuramente: exportar dados
  Future<void> exportChildData(String childId) async {
    debugPrint('Exportando dados da criança: $childId');
    // Implementação futura
  }

  // Futuramente: compartilhar relatório
  Future<void> shareReport(String childId) async {
    debugPrint('Compartilhando relatório: $childId');
    // Implementação futura
  }
}