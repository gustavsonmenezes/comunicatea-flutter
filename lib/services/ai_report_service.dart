import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/speech_log_model.dart';
import '../models/child_profile.dart';

class AiReportService {
  // 🔥 Removida a chave fixa para permitir o push no GitHub.
  // Use: flutter run --dart-define=GROQ_API_KEY=sua_chave_aqui
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _baseUrl = "https://api.groq.com/openai/v1/chat/completions";

  Future<String> generateClinicalInsight(ChildProfile child, List<SpeechLog> logs) async {
    try {
      debugPrint('🚀 GROQ IA: Gerando plano de intervenção para ${child.name}...');
      
      if (logs.isEmpty) {
        return "Ainda não há dados de fala suficientes para gerar um relatório sobre este aluno.";
      }

      if (_apiKey.isEmpty) {
        return "Erro: Chave da API não configurada. Use --dart-define=GROQ_API_KEY na execução.";
      }

      final totalTentativas = logs.length;
      final sucessos = logs.where((l) => l.isSuccess).length;
      final taxaSucesso = (sucessos / totalTentativas * 100).toStringAsFixed(1);
      final palavrasDificies = _identificarPalavrasDificies(logs);

      final prompt = """
      Você é um especialista em Fonoaudiologia e TEA. Analise estes dados:
      - Aluno: ${child.name}
      - Desempenho: $taxaSucesso% de acerto em $totalTentativas tentativas.
      - Palavras críticas (erros repetidos): ${palavrasDificies.join(', ')}

      Com base nisso, gere um insight clínico de no máximo 4 linhas que responda:
      1. Qual a provável área de dificuldade?
      2. Em qual área específica o profissional deve focar a intervenção agora?
      3. Sugira uma atividade ou estímulo prático.
      
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
              "content": "Você é um supervisor clínico de fonoaudiologia."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.6,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].trim();
      } else {
        return "Erro na IA (${response.statusCode}).";
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
