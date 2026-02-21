import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/core/ai/ai_observability.dart';

void main() {
  group('AiObservability', () {
    late AiObservability observability;

    setUp(() {
      observability = AiObservability.instance;
      observability.reset();
    });

    test('starts with zero metrics', () {
      final snap = observability.snapshot;

      expect(snap.totalCalls, 0);
      expect(snap.totalErrors, 0);
      expect(snap.totalCacheHits, 0);
      expect(snap.totalInputTokens, 0);
      expect(snap.totalOutputTokens, 0);
      expect(snap.totalLatencyMs, 0);
    });

    test('recordSuccess increments counters', () {
      observability.recordSuccess(
        feature: 'report',
        latency: const Duration(milliseconds: 1500),
        inputTokens: 100,
        outputTokens: 200,
        fromCache: false,
      );

      final snap = observability.snapshot;
      expect(snap.totalCalls, 1);
      expect(snap.totalErrors, 0);
      expect(snap.totalLatencyMs, 1500);
      expect(snap.totalInputTokens, 100);
      expect(snap.totalOutputTokens, 200);
      expect(snap.totalCacheHits, 0);
    });

    test('recordSuccess tracks cache hits', () {
      observability.recordSuccess(
        feature: 'consistency',
        latency: const Duration(milliseconds: 500),
        inputTokens: 50,
        outputTokens: 80,
        fromCache: true,
      );

      expect(observability.snapshot.totalCacheHits, 1);
    });

    test('recordError increments error counter', () {
      observability.recordError(
        feature: 'risk',
        error: Exception('Timeout'),
        latency: const Duration(milliseconds: 30000),
      );

      final snap = observability.snapshot;
      expect(snap.totalCalls, 1);
      expect(snap.totalErrors, 1);
      expect(snap.totalLatencyMs, 30000);
    });

    test('multiple calls accumulate correctly', () {
      observability.recordSuccess(
        feature: 'report',
        latency: const Duration(milliseconds: 1000),
        inputTokens: 100,
        outputTokens: 200,
        fromCache: false,
      );
      observability.recordSuccess(
        feature: 'risk',
        latency: const Duration(milliseconds: 2000),
        inputTokens: 150,
        outputTokens: 300,
        fromCache: true,
      );
      observability.recordError(
        feature: 'consistency',
        error: 'Error',
        latency: const Duration(milliseconds: 500),
      );

      final snap = observability.snapshot;
      expect(snap.totalCalls, 3);
      expect(snap.totalErrors, 1);
      expect(snap.totalCacheHits, 1);
      expect(snap.totalLatencyMs, 3500);
      expect(snap.totalInputTokens, 250);
      expect(snap.totalOutputTokens, 500);
    });

    test('averageLatencyMs calculated correctly', () {
      observability.recordSuccess(
        feature: 'a',
        latency: const Duration(milliseconds: 1000),
      );
      observability.recordSuccess(
        feature: 'b',
        latency: const Duration(milliseconds: 3000),
      );

      expect(observability.snapshot.averageLatencyMs, 2000.0);
    });

    test('errorRate calculated correctly', () {
      observability.recordSuccess(
        feature: 'a',
        latency: const Duration(milliseconds: 100),
      );
      observability.recordError(
        feature: 'b',
        error: 'err',
        latency: const Duration(milliseconds: 100),
      );

      expect(observability.snapshot.errorRate, 0.5);
    });

    test('reset clears all metrics', () {
      observability.recordSuccess(
        feature: 'report',
        latency: const Duration(milliseconds: 1000),
        inputTokens: 100,
        outputTokens: 200,
        fromCache: false,
      );

      observability.reset();
      final snap = observability.snapshot;

      expect(snap.totalCalls, 0);
      expect(snap.totalErrors, 0);
    });
  });

  group('AiMetricsSnapshot', () {
    test('totalTokens sums input and output', () {
      const snap = AiMetricsSnapshot(
        totalCalls: 1,
        totalErrors: 0,
        totalCacheHits: 0,
        totalInputTokens: 100,
        totalOutputTokens: 200,
        totalLatencyMs: 1000,
        averageLatencyMs: 1000,
        errorRate: 0,
      );

      expect(snap.totalTokens, 300);
    });

    test('cacheHitRate calculated correctly', () {
      const snap = AiMetricsSnapshot(
        totalCalls: 4,
        totalErrors: 0,
        totalCacheHits: 2,
        totalInputTokens: 0,
        totalOutputTokens: 0,
        totalLatencyMs: 0,
        averageLatencyMs: 0,
        errorRate: 0,
      );

      expect(snap.cacheHitRate, 0.5);
    });

    test('cacheHitRate returns 0 when no calls', () {
      const snap = AiMetricsSnapshot(
        totalCalls: 0,
        totalErrors: 0,
        totalCacheHits: 0,
        totalInputTokens: 0,
        totalOutputTokens: 0,
        totalLatencyMs: 0,
        averageLatencyMs: 0,
        errorRate: 0,
      );

      expect(snap.cacheHitRate, 0);
    });
  });
}
