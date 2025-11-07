import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olpha_app/features/checkin/application/notifiers/checkin_notifier.dart';

final checkInNotifierProvider = StateNotifierProvider<CheckInNotifier, CheckInState>(
  (ref) => CheckInNotifier(ref),
);
