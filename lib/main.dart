import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:olpha_app/features/ai/presentation/screens/ai_test_page.dart';
import 'package:olpha_app/features/home/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const OlphaApp());
}

class OlphaApp extends StatelessWidget {
  const OlphaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Olpha',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/home',
      routes: {
        '/home': (_) => const HomeScreen(),
        '/ai-test': (_) => const AiTestPage(),  // <--- Add this
      },
    );
  }
}
