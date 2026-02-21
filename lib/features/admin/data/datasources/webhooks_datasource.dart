import '../../../../core/network/api_client.dart';
import '../models/webhook_model.dart';

/// Remote data source for Webhook management
abstract class WebhooksRemoteDataSource {
  /// Get all webhooks
  Future<List<WebhookModel>> getWebhooks();

  /// Get a specific webhook by ID
  Future<WebhookModel> getWebhook(String id);

  /// Create a new webhook
  Future<WebhookModel> createWebhook({
    required String url,
    required List<String> events,
  });

  /// Update an existing webhook
  Future<WebhookModel> updateWebhook(
    String id, {
    String? url,
    List<String>? events,
    bool? isActive,
  });

  /// Disable (soft delete) a webhook
  Future<void> disableWebhook(String id);

  /// Get delivery logs for a webhook
  Future<WebhookDeliveriesResultModel> getDeliveries(
    String webhookId, {
    int page = 1,
    int limit = 20,
    String? event,
    String? status,
  });

  /// Send a test event to a webhook
  Future<TestEventResult> sendTestEvent(String webhookId, String eventType);
}

/// Result of sending a test event
class TestEventResult {
  const TestEventResult({
    required this.success,
    required this.eventId,
  });

  factory TestEventResult.fromJson(Map<String, dynamic> json) => TestEventResult(
      success: json['success'] as bool? ?? false,
      eventId: json['eventId'] as String? ?? '',
    );

  final bool success;
  final String eventId;
}

class WebhooksRemoteDataSourceImpl implements WebhooksRemoteDataSource {
  const WebhooksRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<WebhookModel>> getWebhooks() async {
    final response = await _apiClient.get<Map<String, dynamic>>('webhooks');
    final data = response.data?['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => WebhookModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WebhookModel> getWebhook(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('webhooks/$id');
    return WebhookModel.fromJson(response.data!);
  }

  @override
  Future<WebhookModel> createWebhook({
    required String url,
    required List<String> events,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'webhooks',
      data: {
        'url': url,
        'events': events,
      },
    );
    return WebhookModel.fromJson(response.data!);
  }

  @override
  Future<WebhookModel> updateWebhook(
    String id, {
    String? url,
    List<String>? events,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (url != null) data['url'] = url;
    if (events != null) data['events'] = events;
    if (isActive != null) data['isActive'] = isActive;

    final response = await _apiClient.put<Map<String, dynamic>>(
      'webhooks/$id',
      data: data,
    );
    return WebhookModel.fromJson(response.data!);
  }

  @override
  Future<void> disableWebhook(String id) async {
    await _apiClient.delete<void>('webhooks/$id');
  }

  @override
  Future<WebhookDeliveriesResultModel> getDeliveries(
    String webhookId, {
    int page = 1,
    int limit = 20,
    String? event,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (event != null) queryParams['event'] = event;
    if (status != null) queryParams['status'] = status;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    final response = await _apiClient.get<Map<String, dynamic>>(
      'webhooks/$webhookId/deliveries?$queryString',
    );
    return WebhookDeliveriesResultModel.fromJson(response.data!);
  }

  @override
  Future<TestEventResult> sendTestEvent(String webhookId, String eventType) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'webhooks/$webhookId/test',
      data: {'event': eventType},
    );
    return TestEventResult.fromJson(response.data!);
  }
}
