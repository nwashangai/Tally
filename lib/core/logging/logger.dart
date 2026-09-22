enum LogLevel { debug, info, warning, error }

/// Abstract port for application logging.
/// Implementations must redact sensitive credentials, tokens, and PII.
abstract interface class Logger {
  void debug(String message, [Map<String, Object?>? metadata]);
  void info(String message, [Map<String, Object?>? metadata]);
  void warning(String message, [Object? error, StackTrace? stackTrace]);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

/// Default development logger with sensitive key redaction.
class AppLogger implements Logger {
  final LogLevel minLevel;

  static const Set<String> _sensitiveKeys = {
    'password',
    'token',
    'secret',
    'authorization',
    'access_token',
    'refresh_token',
    'api_key',
  };

  const AppLogger({this.minLevel = LogLevel.debug});

  @override
  void debug(String message, [Map<String, Object?>? metadata]) {
    if (_shouldLog(LogLevel.debug)) {
      _printLog('DEBUG', message, metadata);
    }
  }

  @override
  void info(String message, [Map<String, Object?>? metadata]) {
    if (_shouldLog(LogLevel.info)) {
      _printLog('INFO', message, metadata);
    }
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.warning)) {
      // ignore: avoid_print
      print('[WARN] $message${error != null ? ' | Error: $error' : ''}');
      if (stackTrace != null) {
        // ignore: avoid_print
        print(stackTrace);
      }
    }
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.error)) {
      // ignore: avoid_print
      print('[ERROR] $message${error != null ? ' | Error: $error' : ''}');
      if (stackTrace != null) {
        // ignore: avoid_print
        print(stackTrace);
      }
    }
  }

  bool _shouldLog(LogLevel level) => level.index >= minLevel.index;

  void _printLog(String tag, String message, Map<String, Object?>? metadata) {
    final sanitized = metadata != null ? ' ${_sanitize(metadata)}' : '';
    // ignore: avoid_print
    print('[$tag] $message$sanitized');
  }

  Map<String, Object?> _sanitize(Map<String, Object?> map) {
    return map.map((key, value) {
      if (_sensitiveKeys.contains(key.toLowerCase())) {
        return MapEntry(key, '[REDACTED]');
      }
      if (value is Map<String, Object?>) {
        return MapEntry(key, _sanitize(value));
      }
      return MapEntry(key, value);
    });
  }
}
