/// Simple debug logger for AGG library.
///
/// This class provides basic logging functionality for debugging purposes.
class DebugLogger {
  static bool _enabled = false;
  static final List<String> _logs = [];
  static int _maxLogs = 1000;

  /// Enables or disables debug logging.
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Checks if debug logging is enabled.
  static bool get isEnabled => _enabled;

  /// Sets the maximum number of log entries to keep.
  static void setMaxLogs(int max) {
    _maxLogs = max;
    _trimLogs();
  }

  /// Logs a debug message.
  static void log(String message) {
    if (!_enabled) return;

    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';

    _logs.add(logEntry);
    _trimLogs();

    // Also print to console in debug mode
    print(logEntry);
  }

  /// Logs a warning message.
  static void warn(String message) {
    log('WARNING: $message');
  }

  /// Logs an error message.
  static void error(String message,
      [Object? exception, StackTrace? stackTrace]) {
    final errorMsg = StringBuffer('ERROR: $message');
    if (exception != null) {
      errorMsg.write('\nException: $exception');
    }
    if (stackTrace != null) {
      errorMsg.write('\nStack trace:\n$stackTrace');
    }
    log(errorMsg.toString());
  }

  /// Gets all log entries.
  static List<String> getLogs() => List.unmodifiable(_logs);

  /// Clears all log entries.
  static void clear() {
    _logs.clear();
  }

  /// Trims logs to maximum size.
  static void _trimLogs() {
    if (_logs.length > _maxLogs) {
      _logs.removeRange(0, _logs.length - _maxLogs);
    }
  }

  /// Logs a formatted message with key-value pairs.
  static void logData(String message, Map<String, dynamic> data) {
    final buffer = StringBuffer(message);
    if (data.isNotEmpty) {
      buffer.write('\n  Data:');
      data.forEach((key, value) {
        buffer.write('\n    $key: $value');
      });
    }
    log(buffer.toString());
  }

  /// Logs performance timing information.
  static void logTiming(String operation, Duration duration) {
    log('TIMING: $operation took ${duration.inMilliseconds}ms');
  }

  /// Creates a stopwatch for timing operations.
  static Stopwatch startTiming() {
    return Stopwatch()..start();
  }

  /// Logs the elapsed time since the stopwatch was started.
  static void endTiming(String operation, Stopwatch stopwatch) {
    stopwatch.stop();
    logTiming(operation, stopwatch.elapsed);
  }
}
