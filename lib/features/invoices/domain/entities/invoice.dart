import 'package:equatable/equatable.dart';

import 'invoice_status.dart';

/// Client info embedded in invoice
class InvoiceClientInfo extends Equatable {
  const InvoiceClientInfo({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.company,
    this.phone,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? company;
  final String? phone;

  String get displayName {
    final name = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    return name.isNotEmpty ? name : (company ?? email);
  }

  @override
  List<Object?> get props => [id, email, firstName, lastName, company, phone];
}

/// Booking info embedded in invoice
class InvoiceBookingInfo extends Equatable {
  const InvoiceBookingInfo({
    required this.id,
    required this.date,
    this.propertyAddress,
  });

  final String id;
  final DateTime date;
  final String? propertyAddress;

  @override
  List<Object?> get props => [id, date, propertyAddress];
}

/// Created by info
class InvoiceCreatedBy extends Equatable {
  const InvoiceCreatedBy({
    required this.id,
    this.firstName,
    this.lastName,
  });

  final String id;
  final String? firstName;
  final String? lastName;

  String get displayName {
    final name = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    return name.isNotEmpty ? name : 'Unknown';
  }

  @override
  List<Object?> get props => [id, firstName, lastName];
}

/// Invoice line item
class InvoiceItem extends Equatable {
  const InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    this.itemType,
  });

  final String id;
  final String description;
  final int quantity;
  final int unitPrice; // in pence
  final int amount; // in pence
  final String? itemType;

  @override
  List<Object?> get props => [id, description, quantity, unitPrice, amount, itemType];
}

/// Invoice summary for list views
class Invoice extends Equatable {
  const Invoice({
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

  final String id;
  final String invoiceNumber;
  final InvoiceStatus status;
  final String clientId;
  final String clientName;
  final String? bookingId;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final int subtotal; // in pence
  final double taxRate;
  final int taxAmount; // in pence
  final int total; // in pence
  final DateTime createdAt;

  /// Format amount as currency (GBP)
  String formatAmount(int pence) {
    final pounds = pence / 100;
    return '\u00A3${pounds.toStringAsFixed(2)}';
  }

  String get formattedTotal => formatAmount(total);
  String get formattedSubtotal => formatAmount(subtotal);
  String get formattedTaxAmount => formatAmount(taxAmount);

  /// Check if invoice is overdue
  bool get isOverdue {
    if (status != InvoiceStatus.issued || dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        status,
        clientId,
        clientName,
        bookingId,
        issueDate,
        dueDate,
        paidDate,
        subtotal,
        taxRate,
        taxAmount,
        total,
        createdAt,
      ];
}

/// Full invoice detail with items and relations
class InvoiceDetail extends Invoice {
  const InvoiceDetail({
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

  final List<InvoiceItem> items;
  final String? notes;
  final String? paymentTerms;
  final String? cancellationReason;
  final DateTime? cancelledDate;
  final InvoiceClientInfo client;
  final InvoiceBookingInfo? booking;
  final InvoiceCreatedBy createdBy;

  @override
  List<Object?> get props => [
        ...super.props,
        items,
        notes,
        paymentTerms,
        cancellationReason,
        cancelledDate,
        client,
        booking,
        createdBy,
      ];
}
