/// Invoice status enum matching backend
enum InvoiceStatus {
  draft,
  issued,
  paid,
  cancelled;

  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.issued:
        return 'Issued';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  String toBackendString() => name.toUpperCase();

  static InvoiceStatus fromBackendString(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return InvoiceStatus.draft;
      case 'ISSUED':
        return InvoiceStatus.issued;
      case 'PAID':
        return InvoiceStatus.paid;
      case 'CANCELLED':
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.draft;
    }
  }
}
