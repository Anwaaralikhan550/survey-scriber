import '../../domain/entities/webhook.dart';

/// Webhook model with JSON serialization
class WebhookModel extends Webhook {
  const WebhookModel({
    required super.id,
    required super.url,
    required super.events,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.secret,
  });

  factory WebhookModel.fromJson(Map<String, dynamic> json) => WebhookModel(
      id: json['id'] as String,
      url: json['url'] as String,
      events: (json['events'] as List<dynamic>).cast<String>(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      secret: json['secret'] as String?,
    );

  Map<String, dynamic> toJson() => {
      'id': id,
      'url': url,
      'events': events,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (secret != null) 'secret': secret,
    };
}

/// Webhook delivery model with JSON serialization
class WebhookDeliveryModel extends WebhookDelivery {
  const WebhookDeliveryModel({
    required super.id,
    required super.webhookId,
    required super.event,
    required super.status,
    required super.createdAt,
    super.eventId,
    super.responseStatusCode,
    super.responseBody,
    super.attempts,
    super.lastAttemptAt,
    super.nextAttemptAt,
    super.lastError,
    super.isTest,
  });

  factory WebhookDeliveryModel.fromJson(Map<String, dynamic> json) => WebhookDeliveryModel(
      id: json['id'] as String,
      webhookId: json['webhookId'] as String,
      event: json['event'] as String,
      eventId: json['eventId'] as String?,
      status: _parseStatus(json['status'] as String),
      responseStatusCode: json['responseStatusCode'] as int?,
      responseBody: json['responseBody'] as String?,
      attempts: json['attempts'] as int? ?? 1,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
      nextAttemptAt: json['nextAttemptAt'] != null
          ? DateTime.parse(json['nextAttemptAt'] as String)
          : null,
      lastError: json['lastError'] as String?,
      isTest: json['isTest'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

  static WebhookDeliveryStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return WebhookDeliveryStatus.success;
      case 'FAILED':
      default:
        return WebhookDeliveryStatus.failed;
    }
  }
}

/// Paginated webhook deliveries result model
class WebhookDeliveriesResultModel extends WebhookDeliveriesResult {
  const WebhookDeliveriesResultModel({
    required super.deliveries,
    required super.page,
    required super.limit,
    required super.total,
    required super.totalPages,
  });

  factory WebhookDeliveriesResultModel.fromJson(Map<String, dynamic> json) {
    final deliveries = (json['data'] as List<dynamic>)
        .map((e) => WebhookDeliveryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return WebhookDeliveriesResultModel(
      deliveries: deliveries,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? deliveries.length,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}
