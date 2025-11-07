import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olpha_app/features/checkin/application/providers/checkin_provider.dart';

class CheckInScreen extends ConsumerWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkInNotifierProvider);
    final ctrl = ref.read(checkInNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Check-In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('How are you feeling today?', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            // slider 0-4
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final selected = state.mood == i;
                return IconButton(
                  icon: Icon(
                    selected ? Icons.circle : Icons.circle_outlined,
                    size: selected ? 28 : 22,
                  ),
                  onPressed: () => ctrl.setMood(i),
                );
              }),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: state.loading ? null : () => ctrl.submitCheckIn(),
              icon: state.loading ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.send),
              label: const Text('Submit Check-In'),
            ),
            const SizedBox(height: 24),
            if (state.aiReply.isNotEmpty) ...[
              const Text('Olpha says:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(state.aiReply),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
