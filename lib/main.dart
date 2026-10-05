import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'core/app_colors.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/splash_screen.dart';
import 'services/push_notification_service.dart';

final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

bool _firebaseReady = false;
bool _deferredServicesStarted = false;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Only initialize what the app needs before AuthGate can safely render.
///
/// Keeping FCM setup out of this method prevents notification startup work from
/// competing with the first branded Flutter frame.
Future<void> initializeIsdaLinkCore() async {
  if (_firebaseReady) {
    return;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  _firebaseReady = true;
}

/// Starts services that do not need to delay the first usable screen.
Future<void> initializeDeferredIsdaLinkServices() async {
  if (_deferredServicesStarted) {
    return;
  }

  _deferredServicesStarted = true;

  // Give the destination screen one clean frame before FCM creates additional
  // platform/background work. Initial notification taps are still recovered by
  // PushNotificationService through getInitialMessage().
  await Future<void>.delayed(const Duration(milliseconds: 450));

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await PushNotificationService.instance.initialize(
    messengerKey: appMessengerKey,
    navigatorKey: appNavigatorKey,
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Render immediately. Firebase initialization happens on the lightweight
  // Flutter splash instead of blocking runApp().
  runApp(const IsdaLinkApp());
}

class IsdaLinkApp extends StatelessWidget {
  const IsdaLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IsdaLink',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appMessengerKey,
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue),
        useMaterial3: true,
      ),
      home: StartupSplash(
        initialize: initializeIsdaLinkCore,
        onDestinationShown: initializeDeferredIsdaLinkServices,
        destinationBuilder: (_) => const AuthGate(),
      ),
    );
  }
}
