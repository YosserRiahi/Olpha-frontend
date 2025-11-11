import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olpha_app/features/ai/data/ask_gemini.dart';

class AiTestPage extends ConsumerStatefulWidget {
  const AiTestPage({super.key});

  @override
  ConsumerState<AiTestPage> createState() => _AiTestPageState();
}

class _AiTestPageState extends ConsumerState<AiTestPage> {
  final TextEditingController _controller = TextEditingController();
  String? _response;
  bool _isLoading = false;

  Future<void> _sendPrompt() async {
    final promptText = _controller.text.trim();
    if (promptText.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await askGemini(promptText);
      setState(() => _response = result);
    } catch (e) {
      setState(() => _response = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Test Page")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Type a prompt (e.g., give parenting tip)",
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 4,
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isLoading ? null : _sendPrompt,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Send to AI"),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _response ?? "Your response will appear here...",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
