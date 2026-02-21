import 'package:flutter/material.dart';

import '../../domain/entities/invoice_status.dart';

class InvoiceStatusChip extends StatelessWidget {
  const InvoiceStatusChip({
    super.key,
    required this.status,
    this.isOverdue = false,
  });

  final InvoiceStatus status;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final (color, textColor, icon) = _getStatusStyle();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            isOverdue && status == InvoiceStatus.issued ? 'Overdue' : status.displayName,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, IconData) _getStatusStyle() {
    if (isOverdue && status == InvoiceStatus.issued) {
      return (Colors.orange, Colors.orange.shade700, Icons.warning_amber_rounded);
    }

    switch (status) {
      case InvoiceStatus.draft:
        return (Colors.grey, Colors.grey.shade700, Icons.edit_outlined);
      case InvoiceStatus.issued:
        return (Colors.blue, Colors.blue.shade700, Icons.send_outlined);
      case InvoiceStatus.paid:
        return (Colors.green, Colors.green.shade700, Icons.check_circle_outlined);
      case InvoiceStatus.cancelled:
        return (Colors.red, Colors.red.shade700, Icons.cancel_outlined);
    }
  }
}
