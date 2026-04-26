import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/speech_log_model.dart';
import '../models/child_profile.dart';

class AiReportService {
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _baseUrl = "https://api.groq.com/openai/v1/chat/completions";

  Future<String> generateClinicalInsight(
    ChildProfile child, 
    List<SpeechLog> logs,
    List<Map<String, dynamic>> performanceHistory,
  ) async {
    try {
      debugPrint('🚀 GROQ IA: Analisando tendência humanizada para ${child.name}...');
      
      if (logs.isEmpty) {
        return "Ainda não há dados de fala suficientes para gerar uma análise sobre o progresso de ${child.name}.";
      }

      if (_apiKey.isEmpty) {
        return "Erro: Chave da API não configurada.";
      }

      final totalTentativas = logs.length;
      final sucessos = logs.where((l) => l.isSuccess).length;
      final taxaSucesso = (sucessos / totalTentativas * 100).toStringAsFixed(0);
      final palavrasDificies = _identificarPalavrasDificies(logs);

      String tendenciaDescricao = performanceHistory.map((h) => "${h['day']}: ${h['rate'].toStringAsFixed(0)}%").join(", ");

      final prompt = """
      Você é um especialista em Fonoaudiologia e TEA com uma abordagem muito humanizada e empática. 
      Analise a evolução de ${child.name}:
      
      - Desempenho Geral: $taxaSucesso% de acerto em $totalTentativas atividades.
      - Evolução nos últimos dias: $tendenciaDescricao
      - Palavras que ele(a) está tentando dominar: ${palavrasDificies.join(', ')}

      Com base nesses dados, escreva uma mensagem curta (máximo 4 linhas) para o profissional que o acompanha:
      1. Explique como está o ritmo de aprendizado de forma incentivadora.
      2. Aponte qual a principal necessidade do aluno no momento, usando termos simples (ex: em vez de 'fonética', use 'os sons das palavras').
      3. Sugira uma brincadeira ou atividade leve para a próxima sessão que ajude nessa evolução.
      
      IMPORTANTE: Use um tom acolhedor, evite termos médicos muito difíceis e trate o progresso como uma conquista. Responda em Português (PT-BR).
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
              "content": "Você é um mentor fonoaudiólogo que acredita na comunicação afetuosa e clara."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7, // Aumentei um pouco para a fala ficar mais natural e menos rígida
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].trim();
      } else {
        return "No momento, não consegui analisar os dados. Por favor, tente novamente em instantes.";
      }

    } catch (e) {
      return "Houve um problema na conexão com a análise. Verifique sua internet.";
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
