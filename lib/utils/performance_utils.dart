import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class PerformanceUtils {
  static final PerformanceUtils _instance = PerformanceUtils._internal();
  factory PerformanceUtils() => _instance;
  PerformanceUtils._internal();

  final Map<String, DateTime> _timers = {};
  final Map<String, List<Duration>> _metrics = {};

  /// Start timing a specific operation
  void startTimer(String name) {
    _timers[name] = DateTime.now();
    if (kDebugMode) {
      print('[Performance] Started: $name');
    }
  }

  /// Stop timing and record the duration
  Duration? stopTimer(String name) {
    final startTime = _timers[name];
    if (startTime == null) {
      if (kDebugMode) {
        print('[Performance] Warning: Timer "$name" was not started');
      }
      return null;
    }

    final duration = DateTime.now().difference(startTime);
    _timers.remove(name);

    // Store metric
    if (!_metrics.containsKey(name)) {
      _metrics[name] = [];
    }
    _metrics[name]!.add(duration);

    if (kDebugMode) {
      print('[Performance] Completed: $name in ${duration.inMilliseconds}ms');
    }

    return duration;
  }

  /// Get average duration for a named operation
  Duration? getAverageDuration(String name) {
    final durations = _metrics[name];
    if (durations == null || durations.isEmpty) return null;

    final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    return Duration(milliseconds: (totalMs / durations.length).round());
  }

  /// Clear all metrics for a specific operation
  void clearMetrics(String name) {
    _metrics.remove(name);
    if (kDebugMode) {
      print('[Performance] Cleared metrics for: $name');
    }
  }

  /// Clear all metrics
  void clearAllMetrics() {
    _metrics.clear();
    _timers.clear();
    if (kDebugMode) {
      print('[Performance] Cleared all metrics');
    }
  }

  /// Time an async operation
  static Future<T> measureAsync<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    final instance = PerformanceUtils();
    instance.startTimer(name);
    try {
      final result = await operation();
      return result;
    } finally {
      instance.stopTimer(name);
    }
  }

  /// Time a synchronous operation
  static T measureSync<T>(
    String name,
    T Function() operation,
  ) {
    final instance = PerformanceUtils();
    instance.startTimer(name);
    try {
      final result = operation();
      return result;
    } finally {
      instance.stopTimer(name);
    }
  }

  /// Log a custom performance metric
  void logMetric(String name, dynamic value) {
    if (kDebugMode) {
      print('[Performance] $name: $value');
    }
  }

  /// Get performance report for all operations
  Map<String, Map<String, dynamic>> getPerformanceReport() {
    final report = <String, Map<String, dynamic>>{};

    for (final entry in _metrics.entries) {
      final name = entry.key;
      final durations = entry.value;

      if (durations.isEmpty) continue;

      final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
      final avgMs = (totalMs / durations.length).round();
      final minMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
      final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);

      report[name] = {
        'count': durations.length,
        'average_ms': avgMs,
        'min_ms': minMs,
        'max_ms': maxMs,
        'total_ms': totalMs,
      };
    }

    return report;
  }

  /// Print performance report to console
  void printReport() {
    if (!kDebugMode) return;

    final report = getPerformanceReport();
    if (report.isEmpty) {
      print('[Performance] No metrics recorded');
      return;
    }

    print('\n========== Performance Report ==========');
    for (final entry in report.entries) {
      final name = entry.key;
      final stats = entry.value;
      print('\n$name:');
      print('  Count: ${stats['count']}');
      print('  Average: ${stats['average_ms']}ms');
      print('  Min: ${stats['min_ms']}ms');
      print('  Max: ${stats['max_ms']}ms');
      print('  Total: ${stats['total_ms']}ms');
    }
    print('\n========================================\n');
  }

  /// Monitor frame build time
  static void monitorFrameBuilds(String screenName) {
    if (!kDebugMode) return;

    WidgetsBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
      for (final timing in timings) {
        final buildTime = timing.buildDuration;
        final rasterTime = timing.rasterDuration;
        final totalTime = timing.totalSpan;

        if (buildTime.inMilliseconds > 16) {
          print('[Performance] Slow frame in $screenName:');
          print('  Build: ${buildTime.inMilliseconds}ms');
          print('  Raster: ${rasterTime.inMilliseconds}ms');
          print('  Total: ${totalTime.inMilliseconds}ms');
        }
      }
    });
  }

  /// Debounce function calls
  static Timer? _debounceTimer;
  static void debounce(Duration duration, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  /// Throttle function calls
  static DateTime? _lastThrottleTime;
  static void throttle(Duration duration, VoidCallback callback) {
    final now = DateTime.now();
    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) >= duration) {
      _lastThrottleTime = now;
      callback();
    }
  }
}
