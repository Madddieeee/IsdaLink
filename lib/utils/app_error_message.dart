import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

class AppErrorMessage {
  const AppErrorMessage._();

  static String from(
    Object error, {
    required String fallback,
    bool allowBusinessMessage = false,
  }) {
    if (error is FirebaseException) {
      return _firebaseMessage(error, fallback: fallback);
    }

    if (error is SocketException || error is TimeoutException) {
      return _networkMessage;
    }

    final text = _clean(error);
    final lower = text.toLowerCase();

    if (_looksLikeNetworkError(lower)) {
      return _networkMessage;
    }

    if (_looksLikePermissionError(lower)) {
      return _permissionMessage;
    }

    if (allowBusinessMessage && _isSafeBusinessMessage(text)) {
      return text;
    }

    return fallback;
  }

  static String _firebaseMessage(
    FirebaseException error, {
    required String fallback,
  }) {
    final code = error.code.trim().toLowerCase();

    switch (code) {
      case 'network-request-failed':
      case 'unavailable':
        return _networkMessage;
      case 'deadline-exceeded':
      case 'retry-limit-exceeded':
        return 'The request took too long to complete. Check your connection and try again.';
      case 'permission-denied':
      case 'unauthorized':
        return _permissionMessage;
      case 'unauthenticated':
        return 'Your session has expired. Please sign in again and retry.';
      case 'not-found':
      case 'object-not-found':
        return 'The requested information could not be found. Refresh the screen and try again.';
      case 'already-exists':
        return 'This information already exists. Refresh the screen before trying again.';
      case 'failed-precondition':
      case 'aborted':
        return 'The information changed while you were working. Refresh the screen and try again.';
      case 'invalid-argument':
        return 'Some submitted information is invalid. Review the details and try again.';
      case 'resource-exhausted':
      case 'quota-exceeded':
        return 'The service is temporarily busy. Please wait a moment and try again.';
      case 'canceled':
      case 'cancelled':
        return 'The operation was cancelled.';
      default:
        return fallback;
    }
  }

  static String _clean(Object error) {
    var text = error.toString().trim();

    const prefixes = <String>[
      'Exception: ',
      'StateError: ',
      'Bad state: ',
    ];

    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
      }
    }

    return text;
  }

  static bool _looksLikeNetworkError(String text) {
    return text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('connection reset') ||
        text.contains('connection closed') ||
        text.contains('network is unreachable') ||
        text.contains('clientexception') && text.contains('http');
  }

  static bool _looksLikePermissionError(String text) {
    return text.contains('permission-denied') ||
        text.contains('permission denied') ||
        text.contains('unauthorized');
  }

  static bool _isSafeBusinessMessage(String text) {
    if (text.isEmpty || text.length > 240) {
      return false;
    }

    final lower = text.toLowerCase();
    const technicalMarkers = <String>[
      'firebaseexception',
      'platformexception',
      'stack trace',
      'package:',
      'dart:',
      'http://',
      'https://',
      '[cloud_firestore',
      '[firebase_',
    ];

    return !technicalMarkers.any(lower.contains);
  }

  static const String _networkMessage =
      'Unable to reach IsdaLink right now. Check your internet connection and try again.';

  static const String _permissionMessage =
      'You do not have permission to complete this action. Refresh the screen or sign in again.';
}
