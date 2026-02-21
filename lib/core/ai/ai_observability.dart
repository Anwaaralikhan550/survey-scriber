import 'dart:developer' as developer;

import '../utils/logger.dart';

/// Lightweight observability for AI API calls.
///
/// Tracks latency, token usage, cache hits, and errors.
/// Logs via [AppLogger] and [developer.log] for DevTools timeline.
class AiObservability {
  static const _tag = 'AiObservability';

  /// Singleton for app-wide metrics accumulation.
  static final instance = AiObservability._();
  AiObservability._();

  // ── Session-level counters ──────────────────────────────────────

  int _totalCalls = 0;
  int _totalErrors = 0;
  int _totalCacheHits = 0;
  int _totalInputTokens = 0;
  int _totalOutputTokens = 0;
  Duration _totalLatency = Duration.zero;

  int get totalCalls => _totalCalls;
  int get totalErrors => _totalErrors;
  int get totalCacheHits => _totalCacheHits;
  int get totalInputTokens => _totalInputTokens;
  int get totalOutputTokens => _totalOutputTokens;
  int get totalTokens => _totalInputTokens + _totalOutputTokens;
  Duration get totalLatency => _totalLatency;

  double get averageLatencyMs {
    if (_totalCalls == 0) return 0;
    return _totalLatency.inMilliseconds / _totalCalls;
  }

  double get errorRate {
    if (_totalCalls == 0) return 0;
    return _totalErrors / _totalCalls;
  }

  // ── Tracking methods ────────────────────────────────────────────

  /// Record a successful AI call.
  void recordSuccess({
    required String feature,
    required Duration latency,
    int inputTokens = 0,
    int outputTokens = 0,
    bool fromCache = false,
    String? correlationId,
  }) {
    _totalCalls++;
    _totalLatency += latency;
    _totalInputTokens += inputTokens;
    _totalOutputTokens += outputTokens;
    if (fromCache) _totalCacheHits++;

    AppLogger.d(_tag,
        '$feature OK ${latency.inMilliseconds}ms '
        'tokens=$inputTokens+$outputTokens '
        '${fromCache ? "(cached)" : ""} '
        '${correlationId != null ? "[cid=$correlationId]" : ""}');

    developer.log(
      '$feature: ${latency.inMilliseconds}ms, '
      'tokens=${inputTokens + outputTokens}',
      name: 'ai.metrics',
    );
  }

  /// Record a failed AI call.
  void recordError({
    required String feature,
    required Duration latency,
    required Object error,
    String? correlationId,
  }) {
    _totalCalls++;
    _totalErrors++;
    _totalLatency += latency;

    AppLogger.e(_tag,
        '$feature FAIL ${latency.inMilliseconds}ms: $error '
        '${correlationId != null ? "[cid=$correlationId]" : ""}');

    developer.log(
      '$feature: FAIL after ${latency.inMilliseconds}ms: $error',
      name: 'ai.metrics',
      error: error,
    );
  }

  /// Reset session counters (e.g. on logout).
  void reset() {
    _totalCalls = 0;
    _totalErrors = 0;
    _totalCacheHits = 0;
    _totalInputTokens = 0;
    _totalOutputTokens = 0;
    _totalLatency = Duration.zero;
  }

  /// Get a snapshot of current metrics for display in a debug panel.
  AiMetricsSnapshot get snapshot => AiMetricsSnapshot(
        totalCalls: _totalCalls,
        totalErrors: _totalErrors,
        totalCacheHits: _totalCacheHits,
        totalInputTokens: _totalInputTokens,
        totalOutputTokens: _totalOutputTokens,
        totalLatencyMs: _totalLatency.inMilliseconds,
        averageLatencyMs: averageLatencyMs,
        errorRate: errorRate,
      );
}

/// Immutable snapshot of AI metrics at a point in time.
class AiMetricsSnapshot {
  const AiMetricsSnapshot({
    required this.totalCalls,
    required this.totalErrors,
    required this.totalCacheHits,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalLatencyMs,
    required this.averageLatencyMs,
    required this.errorRate,
  });

  final int totalCalls;
  final int totalErrors;
  final int totalCacheHits;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalLatencyMs;
  final double averageLatencyMs;
  final double errorRate;

  int get totalTokens => totalInputTokens + totalOutputTokens;
  double get cacheHitRate =>
      totalCalls > 0 ? totalCacheHits / totalCalls : 0;
}
