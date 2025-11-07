import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olpha_app/providers/app_providers.dart';

class CheckInState {
  final int mood; // 0-4
  final bool loading;
  final String aiReply;

  CheckInState({required this.mood, required this.loading, required this.aiReply});

  CheckInState copyWith({int? mood, bool? loading, String? aiReply}) {
    return CheckInState(
      mood: mood ?? this.mood,
      loading: loading ?? this.loading,
      aiReply: aiReply ?? this.aiReply,
    );
  }
}

class CheckInNotifier extends StateNotifier<CheckInState> {
  final Ref ref;
  CheckInNotifier(this.ref) : super(CheckInState(mood: 2, loading: false, aiReply: ''));

  void setMood(int m) => state = state.copyWith(mood: m);

  Future<void> submitCheckIn() async {
    state = state.copyWith(loading: true, aiReply: '');
    final ai = ref.read(aiServiceProvider);
    final prompt = _buildPrompt();
    final reply = await ai.askGemini(prompt);
    state = state.copyWith(loading: false, aiReply: reply);
  }

  String _buildPrompt() {
    final moodMap = ['very low', 'low', 'neutral', 'good', 'very good'];
    return "Parent check-in: mood=${moodMap[state.mood]}. "
        "Suggest a 2-minute emotionally supportive micro-action the parent can do with the child, "
        "and a simple routine tweak for today (one sentence each). Keep it warm and playful.";
  }

  String _systemPrompt() {
    return "You are Olpha, a gentle mentor + playful family buddy. "
        "Keep advice nurturing, short, and safe for families with children aged 0-3. "
        "No medical advice. Focus on quick emotional support and tiny parenting actions.";
  }
}
