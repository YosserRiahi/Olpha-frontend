import 'package:go_router/go_router.dart';
import 'package:olpha_app/features/checkin/presentation/screens/checkin_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
  path: '/checkin',
  builder: (context, state) => const CheckInScreen(),
),
  ],
);