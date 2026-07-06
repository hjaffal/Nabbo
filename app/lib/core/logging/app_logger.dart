import 'package:flutter/foundation.dart';

/// Structured logging for the Nabbo app.
/// In production, this would forward to Crashlytics or a logging service.
class AppLogger {
  static void debug(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      _log('DEBUG', message, data: data);
    }
  }

  static void info(String message, {Map<String, dynamic>? data}) {
    _log('INFO', message, data: data);
  }

  static void warning(String message, {Map<String, dynamic>? data}) {
    _log('WARN', message, data: data);
  }

  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log('ERROR', message, data: data);
    if (kDebugMode) {
      if (error != null) debugPrint('  Error: $error');
      if (stackTrace != null) debugPrint('  Stack: $stackTrace');
    }
    // TODO: In production, send to Crashlytics
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Log a capture event
  static void capture({
    required String method,
    required String householdId,
    String? sourceApp,
  }) {
    info('Capture', data: {
      'method': method,
      'householdId': householdId,
      if (sourceApp != null) 'sourceApp': sourceApp,
    });
  }

  /// Log an extraction event
  static void extraction({
    required String messageId,
    required int itemCount,
    required Duration duration,
    bool success = true,
  }) {
    info('Extraction', data: {
      'messageId': messageId,
      'itemCount': itemCount,
      'durationMs': duration.inMilliseconds,
      'success': success,
    });
  }

  /// Log a review action
  static void review({
    required String action,
    required String itemId,
    String? itemType,
  }) {
    info('Review', data: {
      'action': action,
      'itemId': itemId,
      if (itemType != null) 'itemType': itemType,
    });
  }

  static void _log(String level, String message, {Map<String, dynamic>? data}) {
    final timestamp = DateTime.now().toIso8601String();
    final dataStr = data != null ? ' $data' : '';
    debugPrint('[$timestamp] $level: $message$dataStr');
  }
}
