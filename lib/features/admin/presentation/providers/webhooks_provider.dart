import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/webhooks_datasource.dart';
import '../../domain/entities/webhook.dart';

// Data source provider
final webhooksDataSourceProvider = Provider<WebhooksRemoteDataSource>(
  (ref) => WebhooksRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

// ============================================
// Webhooks List State
// ============================================

class WebhooksState {
  const WebhooksState({
    this.webhooks = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.lastCreatedWebhook,
  });

  final List<Webhook> webhooks;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final Webhook? lastCreatedWebhook; // Contains secret on creation

  WebhooksState copyWith({
    List<Webhook>? webhooks,
    bool? isLoading,
    bool? isSaving,
    String? error,
    Webhook? lastCreatedWebhook,
    bool clearCreated = false,
  }) => WebhooksState(
      webhooks: webhooks ?? this.webhooks,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      lastCreatedWebhook: clearCreated ? null : (lastCreatedWebhook ?? this.lastCreatedWebhook),
    );

  int get activeCount => webhooks.where((w) => w.isActive).length;
  int get inactiveCount => webhooks.where((w) => !w.isActive).length;
}

class WebhooksNotifier extends StateNotifier<WebhooksState> {
  WebhooksNotifier(this._dataSource) : super(const WebhooksState());

  final WebhooksRemoteDataSource _dataSource;

  Future<void> loadWebhooks() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      final webhooks = await _dataSource.getWebhooks();
      state = WebhooksState(webhooks: webhooks);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
    }
  }

  Future<bool> createWebhook({
    required String url,
    required List<String> events,
  }) async {
    state = state.copyWith(isSaving: true);

    try {
      final newWebhook = await _dataSource.createWebhook(
        url: url,
        events: events,
      );

      // newWebhook contains the secret (only available at creation)
      final updatedWebhooks = [...state.webhooks, newWebhook];
      state = state.copyWith(
        webhooks: updatedWebhooks,
        isSaving: false,
        lastCreatedWebhook: newWebhook,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  void clearLastCreated() {
    state = state.copyWith(clearCreated: true);
  }

  Future<bool> updateWebhook(
    String id, {
    String? url,
    List<String>? events,
    bool? isActive,
  }) async {
    state = state.copyWith(isSaving: true);

    try {
      final updatedWebhook = await _dataSource.updateWebhook(
        id,
        url: url,
        events: events,
        isActive: isActive,
      );

      final updatedWebhooks = state.webhooks.map((w) {
        if (w.id == id) return updatedWebhook;
        return w;
      }).toList();

      state = state.copyWith(webhooks: updatedWebhooks, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> disableWebhook(String id) async {
    state = state.copyWith(isSaving: true);

    try {
      await _dataSource.disableWebhook(id);

      // Update local state - mark as inactive
      final updatedWebhooks = state.webhooks.map((w) {
        if (w.id == id) return w.copyWith(isActive: false);
        return w;
      }).toList();

      state = state.copyWith(webhooks: updatedWebhooks, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  String _parseError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('400')) {
      return 'Invalid webhook configuration';
    }
    if (errorStr.contains('404')) {
      return 'Webhook not found';
    }
    if (errorStr.contains('409')) {
      return 'A webhook with this URL already exists';
    }
    return 'An error occurred. Please try again.';
  }
}

final webhooksProvider = StateNotifierProvider<WebhooksNotifier, WebhooksState>(
  (ref) => WebhooksNotifier(ref.watch(webhooksDataSourceProvider)),
);

// ============================================
// Webhook Detail State (deliveries + test)
// ============================================

class WebhookDetailState {
  const WebhookDetailState({
    this.webhook,
    this.deliveries = const [],
    this.isLoading = false,
    this.isLoadingDeliveries = false,
    this.isSendingTest = false,
    this.error,
    this.testResult,
    this.deliveriesPage = 1,
    this.deliveriesTotal = 0,
    this.deliveriesTotalPages = 1,
  });

  final Webhook? webhook;
  final List<WebhookDelivery> deliveries;
  final bool isLoading;
  final bool isLoadingDeliveries;
  final bool isSendingTest;
  final String? error;
  final TestEventResult? testResult;
  final int deliveriesPage;
  final int deliveriesTotal;
  final int deliveriesTotalPages;

  bool get hasMoreDeliveries => deliveriesPage < deliveriesTotalPages;

  WebhookDetailState copyWith({
    Webhook? webhook,
    List<WebhookDelivery>? deliveries,
    bool? isLoading,
    bool? isLoadingDeliveries,
    bool? isSendingTest,
    String? error,
    TestEventResult? testResult,
    int? deliveriesPage,
    int? deliveriesTotal,
    int? deliveriesTotalPages,
    bool clearTestResult = false,
  }) => WebhookDetailState(
      webhook: webhook ?? this.webhook,
      deliveries: deliveries ?? this.deliveries,
      isLoading: isLoading ?? this.isLoading,
      isLoadingDeliveries: isLoadingDeliveries ?? this.isLoadingDeliveries,
      isSendingTest: isSendingTest ?? this.isSendingTest,
      error: error,
      testResult: clearTestResult ? null : (testResult ?? this.testResult),
      deliveriesPage: deliveriesPage ?? this.deliveriesPage,
      deliveriesTotal: deliveriesTotal ?? this.deliveriesTotal,
      deliveriesTotalPages: deliveriesTotalPages ?? this.deliveriesTotalPages,
    );
}

class WebhookDetailNotifier extends StateNotifier<WebhookDetailState> {
  WebhookDetailNotifier(this._dataSource) : super(const WebhookDetailState());

  final WebhooksRemoteDataSource _dataSource;

  Future<void> loadWebhook(String webhookId) async {
    state = state.copyWith(isLoading: true);

    try {
      final webhook = await _dataSource.getWebhook(webhookId);
      state = state.copyWith(webhook: webhook, isLoading: false);

      // Also load initial deliveries
      await loadDeliveries(webhookId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadDeliveries(String webhookId, {int page = 1}) async {
    state = state.copyWith(isLoadingDeliveries: true);

    try {
      final result = await _dataSource.getDeliveries(webhookId, page: page);

      final deliveries = page == 1
          ? result.deliveries
          : [...state.deliveries, ...result.deliveries];

      state = state.copyWith(
        deliveries: deliveries,
        isLoadingDeliveries: false,
        deliveriesPage: result.page,
        deliveriesTotal: result.total,
        deliveriesTotalPages: result.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoadingDeliveries: false, error: e.toString());
    }
  }

  Future<void> loadMoreDeliveries() async {
    if (!state.hasMoreDeliveries || state.isLoadingDeliveries) return;
    if (state.webhook == null) return;

    await loadDeliveries(state.webhook!.id, page: state.deliveriesPage + 1);
  }

  Future<bool> sendTestEvent(String eventType) async {
    if (state.webhook == null) return false;

    state = state.copyWith(isSendingTest: true, clearTestResult: true);

    try {
      final result = await _dataSource.sendTestEvent(state.webhook!.id, eventType);
      state = state.copyWith(isSendingTest: false, testResult: result);

      // Refresh deliveries to show the test
      await loadDeliveries(state.webhook!.id);

      return result.success;
    } catch (e) {
      state = state.copyWith(isSendingTest: false, error: e.toString());
      return false;
    }
  }

  void clearTestResult() {
    state = state.copyWith(clearTestResult: true);
  }
}

final webhookDetailProvider =
    StateNotifierProvider.autoDispose<WebhookDetailNotifier, WebhookDetailState>(
  (ref) => WebhookDetailNotifier(ref.watch(webhooksDataSourceProvider)),
);
