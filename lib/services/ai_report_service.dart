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
      if (logs.isEmpty) return "Dados insuficientes.";
      
      final totalTentativas = logs.length;
      final sucessos = logs.where((l) => l.isSuccess).length;
      final taxaSucesso = (sucessos / totalTentativas * 100).toStringAsFixed(0);
      final palavrasDificies = _identificarPalavrasDificies(logs);

      String tendenciaDescricao = performanceHistory.map((h) => "${h['day']}: ${h['rate'].toStringAsFixed(0)}%").join(", ");

      final prompt = """
      Analise a evolução de ${child.name}:
      - Desempenho: $taxaSucesso% de acerto.
      - Tendência: $tendenciaDescricao
      - Palavras críticas: ${palavrasDificies.join(', ')}

      Gere um insight clínico humanizado de 3 linhas com: ritmo de aprendizado, foco atual e uma dica de atividade.
      """;

      return await _callGroq(prompt, "Você é um fonoaudiólogo mentor.");
    } catch (e) {
      return "Erro ao gerar análise: $e";
    }
  }

  // 🔥 NOVO MÉTODO: Resumo para os Pais
  Future<Map<String, dynamic>> generateParentReport(ChildProfile child, List<SpeechLog> logs) async {
    try {
      final prompt = """
      Com base nestes dados de fala da criança ${child.name}:
      ${logs.take(10).map((l) => l.targetWord).join(", ")}

      Crie um resumo encorajador para os pais.
      Retorne APENAS um JSON:
      {
        "message": "Mensagem motivadora curta",
        "highlight": "A maior conquista da semana (ex: Melhorou no som do R)",
        "home_activity": "Uma brincadeira simples para fazer em casa para ajudar na fala",
        "word_of_the_week": "A palavra principal para praticar"
      }
      """;

      final response = await _callGroq(prompt, "Você é um psicopedagogo acolhedor.");
      final jsonStart = response.indexOf('{');
      if (jsonStart == -1) return {};
      return jsonDecode(response.substring(jsonStart, response.lastIndexOf('}') + 1));
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> generatePhonologicalMap(List<SpeechLog> logs) async {
    try {
      final failedLogs = logs.where((l) => !l.isSuccess && l.recognizedWords != null && l.recognizedWords!.isNotEmpty).toList();
      
      if (failedLogs.isEmpty) return {'status': 'sem_dados'};

      final String dadosFala = failedLogs.map((l) => "Alvo: '${l.targetWord}', Falado: '${l.recognizedWords}'").join("; ");

      final prompt = """
      Analise estas trocas de sons na fala de uma criança:
      $dadosFala

      1. Identifique os padrões de substituição (ex: troca G por T).
      2. Crie um PLANO DE INTERVENÇÃO prático.

      Retorne APENAS um JSON no seguinte formato:
      {
        "patterns": [
          {"target": "G", "spoken": "T", "count": 2, "process": "Frontalização"}
        ],
        "summary": "Breve explicação técnica",
        "intervention": {
          "suggested_words": ["Gato", "Gota", "Galo"],
          "pedagogical_tip": "Uma dica técnica para o fonoaudiólogo usar na sessão",
          "weekly_goal": "Meta para a semana"
        }
      }
      """;

      final response = await _callGroq(prompt, "Você é um especialista em fonética clínica e intervenção precoce.");
      
      final jsonStart = response.indexOf('{');
      if (jsonStart == -1) return {'status': 'erro'};

      final jsonEnd = response.lastIndexOf('}') + 1;
      final jsonString = response.substring(jsonStart, jsonEnd);
      
      return jsonDecode(jsonString);
    } catch (e) {
      return {'status': 'erro'};
    }
  }

  Future<String> _callGroq(String prompt, String systemRole) async {
    if (_apiKey.isEmpty) return "Erro: Chave da API não configurada.";

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemRole},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].trim();
      } else {
        return "Erro na API: ${response.statusCode}";
      }
    } catch (e) {
      return "Erro de conexão.";
    }
  }

  List<String> _identificarPalavrasDificies(List<SpeechLog> logs) {
    Map<String, int> falhas = {};
    for (var log in logs) {
      if (!log.isSuccess) {
        falhas[log.targetWord] = (falhas[log.targetWord] ?? 0) + 1;
      }
    }
    return falhas.entries.where((e) => e.value >= 1).map((e) => e.key).take(3).toList();
  }
}
