import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Custom filter that only logs in debug mode.
/// More reliable than DevelopmentFilter for production builds.
class _DebugOnlyFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // Only log in debug mode - completely silent in profile/release
    return kDebugMode;
  }
}

final appLogger = Logger(
  filter: _DebugOnlyFilter(),
  printer: PrettyPrinter(
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  output: ConsoleOutput(),
);

class AppLogger {
  const AppLogger._();

  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.d(message, error: error, stackTrace: stackTrace);
  }

  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.i(message, error: error, stackTrace: stackTrace);
  }

  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.w(message, error: error, stackTrace: stackTrace);
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.e(message, error: error, stackTrace: stackTrace);
  }

  static void t(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.t(message, error: error, stackTrace: stackTrace);
  }

  static void f(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.f(message, error: error, stackTrace: stackTrace);
  }
}
