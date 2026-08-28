import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/utils/app_error_message.dart';

void main() {
  group('AppErrorMessage', () {
    test('maps Firestore permission errors without exposing internals', () {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );

      expect(
        AppErrorMessage.from(error, fallback: 'Fallback'),
        'You do not have permission to complete this action. Refresh the screen or sign in again.',
      );
    });

    test('maps unavailable Firebase errors to a connection message', () {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );

      expect(
        AppErrorMessage.from(error, fallback: 'Fallback'),
        contains('internet connection'),
      );
    });

    test('maps timeout and socket failures to a connection message', () {
      expect(
        AppErrorMessage.from(
          TimeoutException('timed out'),
          fallback: 'Fallback',
        ),
        contains('internet connection'),
      );

      expect(
        AppErrorMessage.from(
          SocketException('failed host lookup'),
          fallback: 'Fallback',
        ),
        contains('internet connection'),
      );
    });

    test('preserves safe business-rule messages when requested', () {
      expect(
        AppErrorMessage.from(
          Exception('Not enough stock available.'),
          fallback: 'Fallback',
          allowBusinessMessage: true,
        ),
        'Not enough stock available.',
      );
    });

    test('does not expose technical exception text by default', () {
      expect(
        AppErrorMessage.from(
          Exception('internal implementation detail'),
          fallback: 'Please try again.',
        ),
        'Please try again.',
      );
    });
  });
}
