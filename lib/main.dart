import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/app_colors.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';

void
main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const IsdaLinkApp(),
  );
}

class IsdaLinkApp
    extends
        StatelessWidget {
  const IsdaLinkApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title: 'IsdaLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
