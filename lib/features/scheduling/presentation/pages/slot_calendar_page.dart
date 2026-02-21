import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/time_slot.dart';
import '../providers/scheduling_providers.dart';
import '../widgets/slot_card.dart';

class SlotCalendarPage extends ConsumerStatefulWidget {
  const SlotCalendarPage({super.key});

  @override
  ConsumerState<SlotCalendarPage> createState() => _SlotCalendarPageState();
}

class _SlotCalendarPageState extends ConsumerState<SlotCalendarPage> {
  DateTime _selectedDate = DateTime.now();
  TimeSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSlots();
    });
  }

  void _loadSlots() {
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      final startDate = _selectedDate;
      final endDate = startDate.add(const Duration(days: 6));
      ref.read(slotsNotifierProvider.notifier).loadSlots(
            surveyorId: user.id,
            startDate: startDate,
            endDate: endDate,
          );
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedSlot = null;
    });
    _loadSlots();
  }

  void _selectSlot(TimeSlot slot) {
    setState(() => _selectedSlot = slot);
  }

  void _proceedToBooking() {
    if (_selectedSlot == null) return;

    context.push(
      Routes.schedulingBook,
      extra: {
        'date': _selectedSlot!.date,
        'startTime': _selectedSlot!.startTime,
        'endTime': _selectedSlot!.endTime,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(slotsNotifierProvider);
    final dateFormat = DateFormat('EEE, MMM d');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        title: Text(
          'Select Time Slot',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Date picker section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Date',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dateFormat.format(_selectedDate),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            _selectDate(picked);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Slots section
          Expanded(
            child: _buildSlotsContent(state),
          ),

          // Bottom action
          if (_selectedSlot != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected: ${dateFormat.format(_selectedSlot!.date)} at ${_selectedSlot!.timeRange}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _proceedToBooking,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Continue to Booking'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlotsContent(SlotsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load slots',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(state.error!),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadSlots,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final slotsResponse = state.slotsResponse;
    if (slotsResponse == null) {
      return const Center(child: Text('Select a date to view available slots'));
    }

    // Find the day matching selected date
    final selectedDay = slotsResponse.days.firstWhere(
      (d) =>
          d.date.year == _selectedDate.year &&
          d.date.month == _selectedDate.month &&
          d.date.day == _selectedDate.day,
      orElse: () => DaySlots(
        date: _selectedDate,
        dayOfWeek: _selectedDate.weekday % 7,
        isWorkingDay: false,
        slots: const [],
      ),
    );

    if (!selectedDay.isWorkingDay) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Not a working day',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (selectedDay.exceptionReason != null) ...[
              const SizedBox(height: 8),
              Text(
                selectedDay.exceptionReason!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Slots',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          SlotGrid(
            slots: selectedDay.slots,
            selectedSlot: _selectedSlot,
            onSlotSelected: _selectSlot,
          ),
        ],
      ),
    );
  }
}
