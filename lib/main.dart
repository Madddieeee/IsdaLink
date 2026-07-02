import 'package:flutter/material.dart';
import 'package:isdalink/core/app_colors.dart';
import 'package:isdalink/screens/welcome_screen.dart';

void main() {
  runApp(const IsdaLinkApp());
}

class IsdaLinkApp extends StatelessWidget {
  const IsdaLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IsdaLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
