import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance =
      PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Set<String> _activeRegistrations = <String>{};

  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  bool _initialized = false;
  String? _currentToken;

  Future<void> initialize({
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    _messengerKey = messengerKey;

    if (_initialized) {
      return;
    }

    _initialized = true;

    _messageSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundAlert,
    );

    _tokenSubscription = _messaging.onTokenRefresh.listen(
      (token) {
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          unawaited(
            _registerDevice(
              user,
              tokenOverride: token,
            ),
          );
        }
      },
    );

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (user != null) {
          unawaited(_registerDevice(user));
        }
      },
    );

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      unawaited(_registerDevice(currentUser));
    }
  }

  Future<void> _registerDevice(
    User user, {
    String? tokenOverride,
  }) async {
    final registrationKey = '${user.uid}:${tokenOverride ?? 'current'}';

    if (!_activeRegistrations.add(registrationKey)) {
      return;
    }

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      await _messaging.setAutoInitEnabled(true);

      final token = tokenOverride ?? await _messaging.getToken();

      if (token == null || token.trim().isEmpty) {
        return;
      }

      _currentToken = token;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pushTokens')
          .doc(_tokenDocumentId(token))
          .set(
        <String, dynamic>{
          'userId': user.uid,
          'token': token,
          'platform': defaultTargetPlatform.name,
          'enabled': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint('Push registration skipped: $error');
    } finally {
      _activeRegistrations.remove(registrationKey);
    }
  }

  Future<void> unregisterCurrentDevice() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      final token = _currentToken ?? await _messaging.getToken();

      if (token == null || token.trim().isEmpty) {
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pushTokens')
          .doc(_tokenDocumentId(token))
          .delete();

      _currentToken = null;
    } catch (error) {
      debugPrint('Push registration cleanup skipped: $error');
    }
  }

  Future<void> signOut() async {
    await unregisterCurrentDevice();
    await FirebaseAuth.instance.signOut();
  }

  String _tokenDocumentId(String token) {
    return base64Url.encode(utf8.encode(token)).replaceAll('=', '');
  }

  void _showForegroundAlert(RemoteMessage message) {
    final title = message.notification?.title ??
        message.data['title']?.toString().trim() ??
        'IsdaLink';
    final body = message.notification?.body ??
        message.data['message']?.toString().trim() ??
        '';
    final messenger = _messengerKey?.currentState;

    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            body.isEmpty ? title : '$title\n$body',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
  }
}
