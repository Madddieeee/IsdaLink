import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/services/notification_navigation_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance =
      PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Set<String> _activeRegistrations = <String>{};
  final Set<String> _shownMessageIds = <String>{};
  final Set<String> _handledInteractionIds = <String>{};

  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  GlobalKey<NavigatorState>? _navigatorKey;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  bool _initialized = false;
  String? _currentToken;

  Future<void> initialize({
    required GlobalKey<ScaffoldMessengerState> messengerKey,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    _messengerKey = messengerKey;
    _navigatorKey = navigatorKey;

    if (_initialized) {
      return;
    }

    _initialized = true;

    _messageSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundAlert,
    );

    _messageOpenedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        unawaited(_handleInteraction(message));
      },
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

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_handleInteraction(initialMessage));
      });
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
    final messageKey = _messageKey(message);

    if (_shownMessageIds.contains(messageKey)) {
      return;
    }

    _rememberMessage(
      _shownMessageIds,
      messageKey,
    );

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
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              unawaited(_handleInteraction(message));
            },
          ),
        ),
      );
  }

  Future<void> _handleInteraction(
    RemoteMessage message,
  ) async {
    final interactionKey = _messageKey(message);

    if (_handledInteractionIds.contains(interactionKey)) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final recipientId = message.data['recipientId']?.toString().trim() ?? '';

    if (currentUser == null ||
        (recipientId.isNotEmpty && recipientId != currentUser.uid)) {
      return;
    }

    final navigatorKey = _navigatorKey;

    if (navigatorKey == null) {
      return;
    }

    for (var attempt = 0;
        attempt < 30 && navigatorKey.currentState == null;
        attempt++) {
      await Future<void>.delayed(
        const Duration(milliseconds: 100),
      );
    }

    if (navigatorKey.currentState == null) {
      return;
    }

    _rememberMessage(
      _handledInteractionIds,
      interactionKey,
    );

    await _markNotificationRead(
      message: message,
      userId: currentUser.uid,
    );

    NotificationNavigationService.open(
      navigatorKey: navigatorKey,
      data: message.data,
    );
  }

  Future<void> _markNotificationRead({
    required RemoteMessage message,
    required String userId,
  }) async {
    final notificationId =
        message.data['notificationId']?.toString().trim() ?? '';
    final type = message.data['type']?.toString().trim() ?? '';
    final unreadCount = int.tryParse(
          message.data['unreadCount']?.toString() ?? '',
        ) ??
        1;
    final grouped =
        message.data['grouped']?.toString().toLowerCase() == 'true' ||
            unreadCount > 1;

    try {
      if (grouped && type.isNotEmpty) {
        final snapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();
        final documents = snapshot.docs.where((document) {
          final data = document.data();
          return data['isRead'] != true &&
              data['type']?.toString().trim() == type;
        }).toList();

        for (var start = 0; start < documents.length; start += 450) {
          final batch = FirebaseFirestore.instance.batch();

          for (final document in documents.skip(start).take(450)) {
            batch.update(
              document.reference,
              {
                'isRead': true,
                'readAt': FieldValue.serverTimestamp(),
              },
            );
          }

          await batch.commit();
        }

        return;
      }

      if (notificationId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notificationId)
            .update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (error) {
      debugPrint('Notification read update skipped: $error');
    }
  }

  String _messageKey(
    RemoteMessage message,
  ) {
    final notificationId =
        message.data['notificationId']?.toString().trim() ?? '';

    if (notificationId.isNotEmpty) {
      return notificationId;
    }

    final messageId = message.messageId?.trim() ?? '';

    if (messageId.isNotEmpty) {
      return messageId;
    }

    final type = message.data['type']?.toString().trim() ?? 'notification';
    final subject = message.data['orderId']?.toString().trim() ??
        message.data['stockId']?.toString().trim() ??
        message.data['subjectId']?.toString().trim() ??
        '';

    return '$type:$subject:${message.sentTime?.millisecondsSinceEpoch ?? 0}';
  }

  void _rememberMessage(
    Set<String> values,
    String value,
  ) {
    values.add(value);

    while (values.length > 120) {
      values.remove(values.first);
    }
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
  }
}
