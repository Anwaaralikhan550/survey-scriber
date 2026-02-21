/// Webhook entity representing a registered webhook endpoint
class Webhook {
  const Webhook({
    required this.id,
    required this.url,
    required this.events,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.secret,
  });

  final String id;
  final String url;
  final List<String> events;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? secret; // Only returned on creation

  Webhook copyWith({
    String? id,
    String? url,
    List<String>? events,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? secret,
  }) => Webhook(
      id: id ?? this.id,
      url: url ?? this.url,
      events: events ?? this.events,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      secret: secret ?? this.secret,
    );
}

/// Webhook delivery log entry
class WebhookDelivery {
  const WebhookDelivery({
    required this.id,
    required this.webhookId,
    required this.event,
    required this.status,
    required this.createdAt,
    this.eventId,
    this.responseStatusCode,
    this.responseBody,
    this.attempts = 1,
    this.lastAttemptAt,
    this.nextAttemptAt,
    this.lastError,
    this.isTest = false,
  });

  final String id;
  final String webhookId;
  final String event;
  final String? eventId;
  final WebhookDeliveryStatus status;
  final int? responseStatusCode;
  final String? responseBody;
  final int attempts;
  final DateTime? lastAttemptAt;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final bool isTest;
  final DateTime createdAt;
}

enum WebhookDeliveryStatus {
  success,
  failed;

  String get displayName {
    switch (this) {
      case WebhookDeliveryStatus.success:
        return 'Success';
      case WebhookDeliveryStatus.failed:
        return 'Failed';
    }
  }
}

/// Supported webhook event types
enum WebhookEventType {
  bookingCreated('BOOKING_CREATED', 'Booking Created'),
  bookingUpdated('BOOKING_UPDATED', 'Booking Updated'),
  bookingCancelled('BOOKING_CANCELLED', 'Booking Cancelled'),
  bookingRequestCreated('BOOKING_REQUEST_CREATED', 'Booking Request Created'),
  bookingRequestApproved('BOOKING_REQUEST_APPROVED', 'Booking Request Approved'),
  bookingChangeApproved('BOOKING_CHANGE_APPROVED', 'Booking Change Approved'),
  invoiceIssued('INVOICE_ISSUED', 'Invoice Issued'),
  invoicePaid('INVOICE_PAID', 'Invoice Paid'),
  reportApproved('REPORT_APPROVED', 'Report Approved');

  const WebhookEventType(this.value, this.displayName);

  final String value;
  final String displayName;

  static WebhookEventType? fromValue(String value) {
    try {
      return WebhookEventType.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

/// Paginated webhook deliveries result
class WebhookDeliveriesResult {
  const WebhookDeliveriesResult({
    required this.deliveries,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<WebhookDelivery> deliveries;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
