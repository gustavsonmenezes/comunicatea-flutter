import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/speech_log_model.dart';
import '../models/child_profile.dart';

class AiReportService {
  static const String _apiKey = "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";
  static const String _baseUrl = "https://api.groq.com/openai/v1/chat/completions";

  Future<String> generateClinicalInsight(ChildProfile child, List<SpeechLog> logs) async {
    try {
      debugPrint('🚀 GROQ IA: Gerando plano de intervenção para ${child.name}...');
      
      if (logs.isEmpty) {
        return "Ainda não há dados de fala suficientes para gerar um relatório sobre este aluno.";
      }

      final totalTentativas = logs.length;
      final sucessos = logs.where((l) => l.isSuccess).length;
      final taxaSucesso = (sucessos / totalTentativas * 100).toStringAsFixed(1);
      final palavrasDificies = _identificarPalavrasDificies(logs);

      // 🔥 Prompt aprimorado para focar em ÁREAS DE INTERVENÇÃO
      final prompt = """
      Você é um especialista em Fonoaudiologia e TEA. Analise estes dados:
      - Aluno: ${child.name}
      - Desempenho: $taxaSucesso% de acerto em $totalTentativas tentativas.
      - Palavras críticas (erros repetidos): ${palavrasDificies.join(', ')}

      Com base nisso, gere um insight clínico de no máximo 4 linhas que responda:
      1. Qual a provável área de dificuldade (ex: fonemas específicos, coordenação motora de fala ou compreensão semântica)?
      2. Em qual área específica o profissional deve focar a intervenção agora para melhorar o desempenho deste aluno?
      3. Sugira uma atividade ou estímulo prático para essa área.
      
      Seja técnico, direto e use o termo 'o aluno'. Responda em Português (PT-BR).
      """;

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system", 
              "content": "Você é um supervisor clínico de fonoaudiologia. Seu objetivo é orientar o profissional de ponta sobre onde focar o tratamento."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.6, // Um pouco mais baixo para ser mais assertivo/técnico
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        return content.trim();
      } else {
        return "Erro na IA (${response.statusCode}). Tente novamente.";
      }

    } catch (e) {
      return "Erro de conexão: $e";
    }
  }

  List<String> _identificarPalavrasDificies(List<SpeechLog> logs) {
    Map<String, int> falhas = {};
    for (var log in logs) {
      if (!log.isSuccess) {
        falhas[log.targetWord] = (falhas[log.targetWord] ?? 0) + 1;
      }
    }
    return falhas.entries
        .where((e) => e.value >= 1)
        .map((e) => e.key)
        .take(3)
        .toList();
  }
}
