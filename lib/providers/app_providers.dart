import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/ai/data/ai_service.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());
