import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:olpha_app/core/utils/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  final _baseUrl = "https://generativelanguage.googleapis.com/v1beta/models";
  final _model = "models/text-bison-001";

  AIService();

  Future<String> askGemini(String prompt) async {
    // final apiKey = await SecureStorage.readApiKey();
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'AI API key not found. Please set it in secure storage.';
    }

    final url = Uri.parse("$_baseUrl/$_model:generateContent?key=$apiKey");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );

    // final payload = {
    //   "model":
    //       "gpt-4o-mini",
    //   "messages": [
    //     if (systemPrompt.isNotEmpty)
    //       {"role": "system", "content": systemPrompt},
    //     {"role": "user", "content": userPrompt},
    //   ],
    //   "max_tokens": 250,
    //   "temperature": 0.8,
    // };

    // final resp = await http.post(
    //   Uri.parse(_baseUrl),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $apiKey',
    //   },
    //   body: json.encode(payload),
    // );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ??
          "⚠️ No response from AI.";
    } else {
      return "❌ Error ${response.statusCode}: ${response.body}";
    }
  }
}
