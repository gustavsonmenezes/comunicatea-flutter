import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/speech_log_model.dart';
import '../models/child_profile.dart';

class AiReportService {
  // 🔥 INSIRA SUA API KEY DA GROQ CLOUD ABAIXO
  static const String _apiKey = "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";
  static const String _baseUrl = "https://api.groq.com/openai/v1/chat/completions";

  Future<String> generateClinicalInsight(ChildProfile child, List<SpeechLog> logs) async {
    try {
      debugPrint('🚀 GROQ IA: Iniciando geração com Llama 3 para ${child.name}...');
      
      if (logs.isEmpty) {
        return "Ainda não há dados de fala suficientes para gerar um relatório sobre este aluno.";
      }

      if (_apiKey == "SUA_GROQ_API_KEY_AQUI") {
        return "Erro: API Key da Groq não configurada no serviço.";
      }

      final totalTentativas = logs.length;
      final sucessos = logs.where((l) => l.isSuccess).length;
      final taxaSucesso = (sucessos / totalTentativas * 100).toStringAsFixed(1);
      final palavrasDificies = _identificarPalavrasDificies(logs);

      final prompt = """
      Você é um assistente de Fonoaudiologia especializado em TEA.
      Analise os dados de uso de um aplicativo de comunicação:
      - Aluno: ${child.name}
      - Total de palavras: $totalTentativas
      - Taxa de acerto: $taxaSucesso%
      - Palavras com dificuldade: ${palavrasDificies.join(', ')}

      Escreva um insight clínico curto (máximo 3 frases). Seja profissional e empático. 
      Responda em português brasileiro.
      """;

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile", // Modelo ultra rápido da Groq
          "messages": [
            {"role": "system", "content": "Você é um fonoaudiólogo especialista em TEA experiente."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        debugPrint('✅ GROQ IA: Resposta recebida com sucesso!');
        return content.trim();
      } else {
        debugPrint('❌ GROQ IA: Erro ${response.statusCode}: ${response.body}');
        return "O serviço de IA está temporariamente indisponível. (Erro: ${response.statusCode})";
      }

    } catch (e) {
      debugPrint('💥 GROQ IA: ERRO: $e');
      return "Não foi possível conectar ao serviço de IA. Verifique sua conexão.";
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
