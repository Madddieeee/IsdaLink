import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/app_colors.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'services/push_notification_service.dart';

final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void
main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await PushNotificationService.instance.initialize(
    messengerKey: appMessengerKey,
    navigatorKey: appNavigatorKey,
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
      scaffoldMessengerKey: appMessengerKey,
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
