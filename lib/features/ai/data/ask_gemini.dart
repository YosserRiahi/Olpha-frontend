import 'ai_service.dart';

final ai = AIService();

Future<String> askGemini(String prompt) async {
  return await ai.askGemini(prompt);
}