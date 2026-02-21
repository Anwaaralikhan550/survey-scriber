import '../../../../core/utils/safe_parsers.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_status.dart';

class InvoiceClientInfoModel {
  const InvoiceClientInfoModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.company,
    this.phone,
  });

  factory InvoiceClientInfoModel.fromJson(Map<String, dynamic> json) => InvoiceClientInfoModel(
      id: asStringOrNull(json['id']) ?? '',
      email: asStringOrNull(json['email']) ?? '',
      firstName: asStringOrNull(json['firstName']),
      lastName: asStringOrNull(json['lastName']),
      company: asStringOrNull(json['company']),
      phone: asStringOrNull(json['phone']),
    );

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? company;
  final String? phone;

  InvoiceClientInfo toEntity() => InvoiceClientInfo(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        company: company,
        phone: phone,
      );
}

class InvoiceBookingInfoModel {
  const InvoiceBookingInfoModel({
    required this.id,
    required this.date,
    this.propertyAddress,
  });

  factory InvoiceBookingInfoModel.fromJson(Map<String, dynamic> json) => InvoiceBookingInfoModel(
      id: asStringOrNull(json['id']) ?? '',
      date: asStringOrNull(json['date']) ?? '',
      propertyAddress: asStringOrNull(json['propertyAddress']),
    );

  final String id;
  final String date;
  final String? propertyAddress;

  InvoiceBookingInfo toEntity() => InvoiceBookingInfo(
        id: id,
        date: parseDateTimeOrDefault(date),
        propertyAddress: propertyAddress,
      );
}

class InvoiceCreatedByModel {
  const InvoiceCreatedByModel({
    required this.id,
    this.firstName,
    this.lastName,
  });

  factory InvoiceCreatedByModel.fromJson(Map<String, dynamic> json) => InvoiceCreatedByModel(
      id: asStringOrNull(json['id']) ?? '',
      firstName: asStringOrNull(json['firstName']),
      lastName: asStringOrNull(json['lastName']),
    );

  final String id;
  final String? firstName;
  final String? lastName;

  InvoiceCreatedBy toEntity() => InvoiceCreatedBy(
        id: id,
        firstName: firstName,
        lastName: lastName,
      );
}

class InvoiceItemModel {
  const InvoiceItemModel({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    this.itemType,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) => InvoiceItemModel(
      id: asStringOrNull(json['id']) ?? '',
      description: asStringOrNull(json['description']) ?? '',
      quantity: asIntOrNull(json['quantity']) ?? 0,
      unitPrice: asIntOrNull(json['unitPrice']) ?? 0,
      amount: asIntOrNull(json['amount']) ?? 0,
      itemType: asStringOrNull(json['itemType']),
    );

  final String id;
  final String description;
  final int quantity;
  final int unitPrice;
  final int amount;
  final String? itemType;

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        if (itemType != null) 'itemType': itemType,
      };

  InvoiceItem toEntity() => InvoiceItem(
        id: id,
        description: description,
        quantity: quantity,
        unitPrice: unitPrice,
        amount: amount,
        itemType: itemType,
      );
}

class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.clientId,
    required this.clientName,
    this.bookingId,
    this.issueDate,
    this.dueDate,
    this.paidDate,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.createdAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
      id: asStringOrNull(json['id']) ?? '',
      invoiceNumber: asStringOrNull(json['invoiceNumber']) ?? '',
      status: asStringOrNull(json['status']) ?? 'DRAFT',
      clientId: asStringOrNull(json['clientId']) ?? '',
      clientName: asStringOrNull(json['clientName']) ?? 'Unknown',
      bookingId: asStringOrNull(json['bookingId']),
      issueDate: asStringOrNull(json['issueDate']),
      dueDate: asStringOrNull(json['dueDate']),
      paidDate: asStringOrNull(json['paidDate']),
      subtotal: asIntOrNull(json['subtotal']) ?? 0,
      taxRate: asDoubleOrNull(json['taxRate']) ?? 0.0,
      taxAmount: asIntOrNull(json['taxAmount']) ?? 0,
      total: asIntOrNull(json['total']) ?? 0,
      createdAt: asStringOrNull(json['createdAt']) ?? '',
    );

  final String id;
  final String invoiceNumber;
  final String status;
  final String clientId;
  final String clientName;
  final String? bookingId;
  final String? issueDate;
  final String? dueDate;
  final String? paidDate;
  final int subtotal;
  final double taxRate;
  final int taxAmount;
  final int total;
  final String createdAt;

  Invoice toEntity() => Invoice(
        id: id,
        invoiceNumber: invoiceNumber,
        status: InvoiceStatus.fromBackendString(status),
        clientId: clientId,
        clientName: clientName,
        bookingId: bookingId,
        issueDate: tryParseDateTime(issueDate),
        dueDate: tryParseDateTime(dueDate),
        paidDate: tryParseDateTime(paidDate),
        subtotal: subtotal,
        taxRate: taxRate,
        taxAmount: taxAmount,
        total: total,
        createdAt: parseDateTimeOrDefault(createdAt),
      );
}

class InvoiceDetailModel extends InvoiceModel {
  const InvoiceDetailModel({
    required super.id,
    required super.invoiceNumber,
    required super.status,
    required super.clientId,
    required super.clientName,
    super.bookingId,
    super.issueDate,
    super.dueDate,
    super.paidDate,
    required super.subtotal,
    required super.taxRate,
    required super.taxAmount,
    required super.total,
    required super.createdAt,
    required this.items,
    this.notes,
    this.paymentTerms,
    this.cancellationReason,
    this.cancelledDate,
    required this.client,
    this.booking,
    required this.createdBy,
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    final clientJson = asMapOrNull(json['client']);
    final createdByJson = asMapOrNull(json['createdBy']);
    final bookingJson = asMapOrNull(json['booking']);

    return InvoiceDetailModel(
      id: asStringOrNull(json['id']) ?? '',
      invoiceNumber: asStringOrNull(json['invoiceNumber']) ?? '',
      status: asStringOrNull(json['status']) ?? 'DRAFT',
      clientId: asStringOrNull(json['clientId']) ?? '',
      clientName: asStringOrNull(json['clientName']) ?? 'Unknown',
      bookingId: asStringOrNull(json['bookingId']),
      issueDate: asStringOrNull(json['issueDate']),
      dueDate: asStringOrNull(json['dueDate']),
      paidDate: asStringOrNull(json['paidDate']),
      subtotal: asIntOrNull(json['subtotal']) ?? 0,
      taxRate: asDoubleOrNull(json['taxRate']) ?? 0.0,
      taxAmount: asIntOrNull(json['taxAmount']) ?? 0,
      total: asIntOrNull(json['total']) ?? 0,
      createdAt: asStringOrNull(json['createdAt']) ?? '',
      items: asMapListOrEmpty(json['items'])
          .map(InvoiceItemModel.fromJson)
          .toList(),
      notes: asStringOrNull(json['notes']),
      paymentTerms: asStringOrNull(json['paymentTerms']),
      cancellationReason: asStringOrNull(json['cancellationReason']),
      cancelledDate: asStringOrNull(json['cancelledDate']),
      client: clientJson != null
          ? InvoiceClientInfoModel.fromJson(clientJson)
          : const InvoiceClientInfoModel(id: '', email: ''),
      booking: bookingJson != null
          ? InvoiceBookingInfoModel.fromJson(bookingJson)
          : null,
      createdBy: createdByJson != null
          ? InvoiceCreatedByModel.fromJson(createdByJson)
          : const InvoiceCreatedByModel(id: ''),
    );
  }

  final List<InvoiceItemModel> items;
  final String? notes;
  final String? paymentTerms;
  final String? cancellationReason;
  final String? cancelledDate;
  final InvoiceClientInfoModel client;
  final InvoiceBookingInfoModel? booking;
  final InvoiceCreatedByModel createdBy;

  @override
  InvoiceDetail toEntity() => InvoiceDetail(
        id: id,
        invoiceNumber: invoiceNumber,
        status: InvoiceStatus.fromBackendString(status),
        clientId: clientId,
        clientName: clientName,
        bookingId: bookingId,
        issueDate: tryParseDateTime(issueDate),
        dueDate: tryParseDateTime(dueDate),
        paidDate: tryParseDateTime(paidDate),
        subtotal: subtotal,
        taxRate: taxRate,
        taxAmount: taxAmount,
        total: total,
        createdAt: parseDateTimeOrDefault(createdAt),
        items: items.map((e) => e.toEntity()).toList(),
        notes: notes,
        paymentTerms: paymentTerms,
        cancellationReason: cancellationReason,
        cancelledDate: tryParseDateTime(cancelledDate),
        client: client.toEntity(),
        booking: booking?.toEntity(),
        createdBy: createdBy.toEntity(),
      );
}

class InvoiceListResponse {
  const InvoiceListResponse({
    required this.data,
    required this.pagination,
  });

  factory InvoiceListResponse.fromJson(Map<String, dynamic> json) {
    final paginationJson = asMapOrNull(json['pagination']) ?? {};
    return InvoiceListResponse(
      data: asMapListOrEmpty(json['data'])
          .map(InvoiceModel.fromJson)
          .toList(),
      pagination: PaginationInfo(
        page: asIntOrNull(paginationJson['page']) ?? 1,
        limit: asIntOrNull(paginationJson['limit']) ?? 20,
        total: asIntOrNull(paginationJson['total']) ?? 0,
        totalPages: asIntOrNull(paginationJson['totalPages']) ?? 1,
      ),
    );
  }

  final List<InvoiceModel> data;
  final PaginationInfo pagination;
}

class PaginationInfo {
  const PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;
}
