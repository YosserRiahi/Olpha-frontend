import 'package:flutter/material.dart';
import 'package:olpha_app/core/router/app_router.dart';
import 'package:olpha_app/core/theme.dart' show AppTheme;

class OlphaApp extends StatelessWidget {
  const OlphaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Olpha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}