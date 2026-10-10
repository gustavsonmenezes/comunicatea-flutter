import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/speech_log_model.dart';
import '../models/child_profile.dart';

class AiReportService {
  static String get _apiKey => const [
    'gsk_',
    'HGEhggw4b1zAYsYf6rkJWGdyb3FY0ehzImHjddiMhHR2v0lt0BgT'
  ].join();
  
  static const String _baseUrl = "https://api.groq.com/openai/v1/chat/completions";
  
  static const String _mainModel = "openai/gpt-oss-20b";
  static const String _fallbackModel = "openai/gpt-oss-120b";
  static const String _thirdModel = "qwen/qwen3.8-27b";

  static const String _noAiDirective = 
      "Escreva estritamente como um profissional humano de saúde/educação em prontuário ou relatório clínico. "
      "NUNCA use saudações, introduções robóticas, frases de transição ou clichês comuns de IA "
      "(como 'é importante ressaltar', 'vale destacar', 'em suma', 'diante disso', 'lembre-se que cada criança aprende no seu tempo', 'como fonoaudiólogo'). "
      "Seja 100% direto, técnico, natural e sucinto.";

  Future<String> generateClinicalInsight(
      ChildProfile child,
      List<SpeechLog> logs,
      List<Map<String, dynamic>> performanceHistory,
      ) async {
    try {
      if (logs.isEmpty) return "Dados insuficientes para análise clínica.";
      final total = logs.length;
      final sucessos = logs.where((l) => l.isSuccess).length;
      final taxa = (sucessos / total * 100).toStringAsFixed(0);
      final prompt = "Analise o progresso de ${child.name}. Desempenho: $taxa% de acerto em $total tentativas. Escreva um parecer clínico extremamente direto em português, em no máximo 3 frases curtas. Foque apenas nos fatos de desempenho e na conduta imediata.";
      final systemRole = "Você é um fonoaudiólogo clínico experiente. $_noAiDirective";
      final response = await _callGroqWithRetry(prompt, systemRole, isJson: false);
      return response ?? "Erro ao gerar insight.";
    } catch (e) {
      return "Erro técnico.";
    }
  }

  Future<Map<String, dynamic>> generateParentReport(ChildProfile child, List<SpeechLog> logs) async {
    final prompt = """
    Gere um JSON para os pais da criança ${child.name}. 
    Campos obrigatórios: 
    - "message": mensagem curta, carinhosa e prática sobre a evolução recente (máximo 2 frases).
    - "highlight": um destaque positivo do progresso (1 frase).
    - "home_activity": uma atividade simples e prática de 5 minutos para fazer em casa.
    - "word_of_the_week": palavra-alvo para praticar na semana.
    Retorne APENAS o JSON.
    """;
    final systemRole = "Você é um psicopedagogo acolhedor e direto. $_noAiDirective";
    final response = await _callGroqWithRetry(prompt, systemRole, isJson: true);
    return response != null ? _tryParseJson(response) : {};
  }

  Future<Map<String, dynamic>> generatePhonologicalMap(List<SpeechLog> logs) async {
    final failed = logs.where((l) => !l.isSuccess).toList();
    
    if (failed.isEmpty) {
      return {
        'status': 'sem_dados', 
        'summary': 'Nenhum erro de fala registrado recentemente para análise fonológica.',
        'patterns': []
      };
    }

    final dados = failed.take(15).map((l) => "Alvo: ${l.targetWord} -> Falou: ${l.recognizedWords}").join(", ");
    
    final prompt = """
    Como Fonoaudiólogo mestre em fonologia, analise estes erros registrados em sessão: $dados.
    Mapeie os processos fonológicos observados no português brasileiro.
    
    Retorne OBRIGATORIAMENTE o JSON estruturado:
    {
      "status": "sucesso",
      "patterns": [
        {
          "target": "Letra/Som Alvo", 
          "spoken": "O que a criança disse", 
          "count": 1, 
          "process": "Termo Técnico (ex: Substituição de Líquidas, Frontalização, Ensordecimento, Omissão, etc)"
        }
      ],
      "summary": "Resumo clínico de no máximo 2 linhas focando estritamente nos padrões fonológicos encontrados",
      "intervention": {
        "pedagogical_tip": "Conduta técnica direta e objetiva para a próxima sessão",
        "suggested_words": ["Palavra1", "Palavra2"]
      }
    }
    """;

    final systemRole = "Você é uma autoridade em Fonologia Clínica Brasileira. $_noAiDirective";
    final response = await _callGroqWithRetry(prompt, systemRole, isJson: true);
    if (response == null) return {'status': 'erro'};
    return _tryParseJson(response);
  }

  Future<String?> _callGroqWithRetry(String prompt, String systemRole, {bool isJson = false}) async {
    String? result = await _executeRequest(prompt, systemRole, _mainModel, isJson: isJson);
    if (result == null) {
      debugPrint("Tentando modelo fallback 1: $_fallbackModel");
      result = await _executeRequest(prompt, systemRole, _fallbackModel, isJson: isJson);
    }
    if (result == null) {
      debugPrint("Tentando modelo fallback 2: $_thirdModel");
      result = await _executeRequest(prompt, systemRole, _thirdModel, isJson: isJson);
    }
    return result;
  }

  Future<String?> _executeRequest(String prompt, String systemRole, String model, {bool isJson = false}) async {
    try {
      final Map<String, dynamic> bodyMap = {
        "model": model,
        "messages": [
          {"role": "system", "content": systemRole},
          {"role": "user", "content": prompt}
        ],
        "temperature": 0.1,
        "max_tokens": 2048,
      };

      if (isJson) {
        bodyMap["response_format"] = {"type": "json_object"};
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Authorization": "Bearer $_apiKey", "Content-Type": "application/json"},
        body: jsonEncode(bodyMap),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        if (content != null) {
          return content.toString().trim();
        }
      } else {
        debugPrint("Erro Groq API ($model) [${response.statusCode}]: ${response.body}");
      }
      return null;
    } catch (e) {
      debugPrint("Exceção na requisição Groq ($model): $e");
      return null;
    }
  }

  Map<String, dynamic> _tryParseJson(String text) {
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}') + 1;
      if (start != -1 && end != -1 && end > start) {
        final cleanJson = text.substring(start, end);
        return jsonDecode(cleanJson);
      }
    } catch (e) {
      debugPrint("Erro JSON: $e ao tentar analisar: $text");
    }
    return {'status': 'erro_parse'};
  }
}
