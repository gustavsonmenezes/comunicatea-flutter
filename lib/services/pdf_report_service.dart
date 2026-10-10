import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/child_profile.dart';
import 'package:intl/intl.dart';

class PdfReportService {
  Future<void> generateAndShareReport({
    required ChildProfile child,
    required String? clinicalInsight,
    required Map<String, dynamic>? phonologicalMap,
    required Map<String, dynamic>? stats,
  }) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(child, dateStr),
            pw.SizedBox(height: 20),
            _buildSectionTitle('RESUMO CLÍNICO'),
            pw.Paragraph(
              text: clinicalInsight ?? 'Nenhum insight gerado para este período.',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            if (phonologicalMap != null && phonologicalMap['status'] != 'sem_dados') ...[
              _buildSectionTitle('ANÁLISE FONOLÓGICA'),
              pw.Text(phonologicalMap['summary'] ?? '', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 11)),
              pw.SizedBox(height: 10),
              _buildPhonologicalTable(phonologicalMap['patterns'] ?? []),
              pw.SizedBox(height: 20),
            ],
            _buildSectionTitle('ESTATÍSTICAS DE DESEMPENHO'),
            _buildStatsGrid(stats),
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Documento gerado automaticamente pelo COMUNICA-TEA',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Relatorio_${child.name.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _buildHeader(ChildProfile child, String date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('COMUNICA-TEA',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.Text('Relatório de Evolução Terapêutica',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Paciente: ${child.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Diagnóstico: ${child.diagnosis ?? "TEA"}'),
            pw.Text('Gerado em: $date', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      width: double.infinity,
      child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
    );
  }

  pw.Widget _buildPhonologicalTable(List patterns) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headers: ['Alvo', 'Produção', 'Processo Identificado'],
      data: patterns.map((p) => [
        p['target'] ?? '',
        p['spoken'] ?? '',
        p['process'] ?? '',
      ]).toList(),
    );
  }

  pw.Widget _buildStatsGrid(Map<String, dynamic>? stats) {
    if (stats == null) return pw.Text('Dados estatísticos não disponíveis.');
    
    final successRate = ((stats['success_rate'] ?? 0) * 100).toStringAsFixed(0);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Taxa de Acerto Geral: $successRate%'),
        pw.Text('Total de Tentativas: ${stats['total_attempts'] ?? 0}'),
        pw.Text('Palavra com maior facilidade: ${stats['easiest_word'] ?? "-"}'),
        pw.Text('Palavra com maior desafio: ${stats['hardest_word'] ?? "-"}'),
      ],
    );
  }
}
