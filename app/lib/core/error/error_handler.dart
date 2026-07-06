import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../logging/app_logger.dart';
import 'app_exception.dart';

/// Global error handler for the app.
class ErrorHandler {
  static void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (details) {
      AppLogger.error(
        'Flutter error',
        error: details.exception,
        stackTrace: details.stack,
      );
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Catch async errors not handled by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error('Unhandled async error', error: error, stackTrace: stack);
      return true;
    };
  }

  /// Convert platform exceptions into AppExceptions
  static AppException handle(dynamic error) {
    if (error is AppException) return error;

    if (error is FirebaseAuthException) {
      return AuthException(
        _authMessage(error.code),
        code: error.code,
        originalError: error,
      );
    }

    if (error is FirebaseException) {
      return DataException(
        error.message ?? 'A database error occurred',
        code: error.code,
        originalError: error,
      );
    }

    if (error is TimeoutException) {
      return const NetworkException('Request timed out. Please try again.');
    }

    return DataException(
      error.toString(),
      originalError: error,
    );
  }

  /// User-friendly message for a given error
  static String userMessage(dynamic error) {
    final appError = error is AppException ? error : handle(error);
    return appError.message;
  }

  /// Show error as a snackbar
  static void showError(BuildContext context, dynamic error) {
    final message = userMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  static String _authMessage(String code) => switch (code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' => 'Incorrect password.',
        'email-already-in-use' => 'An account already exists with this email.',
        'weak-password' => 'Password is too weak. Use at least 6 characters.',
        'invalid-email' => 'Please enter a valid email address.',
        'too-many-requests' => 'Too many attempts. Please wait and try again.',
        'network-request-failed' => 'No internet connection.',
        _ => 'Authentication error. Please try again.',
      };
}
