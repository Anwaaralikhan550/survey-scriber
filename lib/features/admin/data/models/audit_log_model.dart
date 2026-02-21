/// Audit Log Model
/// Maps to GET /api/v1/audit-logs response
library;

enum AuditActorType {
  staff,
  client,
  system;

  static AuditActorType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'STAFF':
        return AuditActorType.staff;
      case 'CLIENT':
        return AuditActorType.client;
      case 'SYSTEM':
        return AuditActorType.system;
      default:
        return AuditActorType.system;
    }
  }

  String get displayName {
    switch (this) {
      case AuditActorType.staff:
        return 'Staff';
      case AuditActorType.client:
        return 'Client';
      case AuditActorType.system:
        return 'System';
    }
  }

  String get apiValue => name.toUpperCase();
}

enum AuditEntityType {
  auth,
  booking,
  bookingRequest,
  bookingChangeRequest,
  invoice,
  survey,
  reportPdf,
  webhook;

  static AuditEntityType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'AUTH':
        return AuditEntityType.auth;
      case 'BOOKING':
        return AuditEntityType.booking;
      case 'BOOKING_REQUEST':
        return AuditEntityType.bookingRequest;
      case 'BOOKING_CHANGE_REQUEST':
        return AuditEntityType.bookingChangeRequest;
      case 'INVOICE':
        return AuditEntityType.invoice;
      case 'SURVEY':
        return AuditEntityType.survey;
      case 'REPORT_PDF':
        return AuditEntityType.reportPdf;
      case 'WEBHOOK':
        return AuditEntityType.webhook;
      default:
        return AuditEntityType.auth;
    }
  }

  String get displayName {
    switch (this) {
      case AuditEntityType.auth:
        return 'Authentication';
      case AuditEntityType.booking:
        return 'Booking';
      case AuditEntityType.bookingRequest:
        return 'Booking Request';
      case AuditEntityType.bookingChangeRequest:
        return 'Change Request';
      case AuditEntityType.invoice:
        return 'Invoice';
      case AuditEntityType.survey:
        return 'Survey';
      case AuditEntityType.reportPdf:
        return 'Report PDF';
      case AuditEntityType.webhook:
        return 'Webhook';
    }
  }

  String get apiValue {
    switch (this) {
      case AuditEntityType.bookingRequest:
        return 'BOOKING_REQUEST';
      case AuditEntityType.bookingChangeRequest:
        return 'BOOKING_CHANGE_REQUEST';
      case AuditEntityType.reportPdf:
        return 'REPORT_PDF';
      default:
        return name.toUpperCase();
    }
  }
}

class AuditLogModel {
  const AuditLogModel({
    required this.id,
    required this.actorType,
    this.actorId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.metadata,
    this.ip,
    this.userAgent,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => AuditLogModel(
      id: json['id'] as String,
      actorType: AuditActorType.fromString(json['actorType'] as String),
      actorId: json['actorId'] as String?,
      action: json['action'] as String,
      entityType: AuditEntityType.fromString(json['entityType'] as String),
      entityId: json['entityId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      ip: json['ip'] as String?,
      userAgent: json['userAgent'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

  final String id;
  final AuditActorType actorType;
  final String? actorId;
  final String action;
  final AuditEntityType entityType;
  final String? entityId;
  final Map<String, dynamic>? metadata;
  final String? ip;
  final String? userAgent;
  final DateTime createdAt;

  /// Format action for display (e.g., "change_request.approved" -> "Change Request Approved")
  String get formattedAction => action
        .replaceAll('_', ' ')
        .replaceAll('.', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '',)
        .join(' ');
}

class AuditLogsResponse {
  const AuditLogsResponse({
    required this.logs,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory AuditLogsResponse.fromJson(Map<String, dynamic> json) => AuditLogsResponse(
      logs: (json['logs'] as List<dynamic>)
          .map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );

  final List<AuditLogModel> logs;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
