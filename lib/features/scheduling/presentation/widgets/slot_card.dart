import 'package:flutter/material.dart';

import '../../domain/entities/time_slot.dart';

class SlotCard extends StatelessWidget {
  const SlotCard({
    super.key,
    required this.slot,
    this.onTap,
    this.selected = false,
  });

  final TimeSlot slot;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isAvailable = slot.isAvailable;

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (selected) {
      backgroundColor = colorScheme.primary;
      borderColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
    } else if (isAvailable) {
      backgroundColor = colorScheme.surface;
      borderColor = colorScheme.outline.withOpacity(0.3);
      textColor = colorScheme.onSurface;
    } else {
      backgroundColor = colorScheme.surfaceContainerHighest.withOpacity(0.5);
      borderColor = colorScheme.outline.withOpacity(0.2);
      textColor = colorScheme.onSurface.withOpacity(0.5);
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAvailable
                    ? (selected ? Icons.check_circle : Icons.schedule)
                    : Icons.block,
                size: 18,
                color: textColor,
              ),
              const SizedBox(width: 8),
              Text(
                slot.timeRange,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SlotGrid extends StatelessWidget {
  const SlotGrid({
    super.key,
    required this.slots,
    this.selectedSlot,
    this.onSlotSelected,
  });

  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final ValueChanged<TimeSlot>? onSlotSelected;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No slots available',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        // Compare date, startTime, and endTime for accurate selection
        final isSelected = selectedSlot != null &&
            selectedSlot!.date.year == slot.date.year &&
            selectedSlot!.date.month == slot.date.month &&
            selectedSlot!.date.day == slot.date.day &&
            selectedSlot!.startTime == slot.startTime &&
            selectedSlot!.endTime == slot.endTime;

        return SlotCard(
          slot: slot,
          selected: isSelected,
          onTap: slot.isAvailable ? () => onSlotSelected?.call(slot) : null,
        );
      }).toList(),
    );
  }
}
