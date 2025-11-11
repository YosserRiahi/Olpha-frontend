import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Olpha")),
      body: Center(child:Column(
        children: [
           Text("Home Screen Placeholder"),
          TextButton(
  onPressed: () => Navigator.pushNamed(context, '/ai-test'),
  child: const Text("AI Test Page"),
),
        ],
      )),
    );
  }
}
