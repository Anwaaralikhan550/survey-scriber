import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/availability_exception.dart';
import '../providers/scheduling_providers.dart';
import '../widgets/weekly_availability_editor.dart';

class AvailabilitySettingsPage extends ConsumerStatefulWidget {
  const AvailabilitySettingsPage({super.key});

  @override
  ConsumerState<AvailabilitySettingsPage> createState() =>
      _AvailabilitySettingsPageState();
}

class _AvailabilitySettingsPageState
    extends ConsumerState<AvailabilitySettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(availabilityNotifierProvider.notifier).loadAvailability();
      ref.read(exceptionsNotifierProvider.notifier).loadExceptions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        title: Text(
          'Availability Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.labelLarge,
          tabs: const [
            Tab(text: 'Weekly Schedule'),
            Tab(text: 'Exceptions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WeeklyScheduleTab(),
          _ExceptionsTab(),
        ],
      ),
    );
  }
}

class _WeeklyScheduleTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(availabilityNotifierProvider);

    if (state.isLoading && state.availability.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.availability.isEmpty) {
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
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () {
                ref
                    .read(availabilityNotifierProvider.notifier)
                    .loadAvailability();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return WeeklyAvailabilityEditor(
      availability: state.availability,
      isLoading: state.isLoading,
      onSave: (input) async {
        await ref
            .read(availabilityNotifierProvider.notifier)
            .saveAvailability(input);
      },
    );
  }
}

class _ExceptionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exceptionsNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.exceptions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null && state.exceptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${state.error}'),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () {
                      ref
                          .read(exceptionsNotifierProvider.notifier)
                          .loadExceptions();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.exceptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No exceptions',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add days off or special hours',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.exceptions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final exception = state.exceptions[index];
              return _ExceptionCard(
                exception: exception,
                dateFormat: dateFormat,
                onDelete: () {
                  ref
                      .read(exceptionsNotifierProvider.notifier)
                      .deleteException(exception.id);
                },
              );
            },
          );
        },
      ),
      // Styled to match the "New Booking" button design
      floatingActionButton: FilledButton.icon(
        onPressed: () => _showAddExceptionDialog(context, ref),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Exception'),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const StadiumBorder(),
          elevation: 3,
          shadowColor: colorScheme.primary.withOpacity(0.4),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Future<void> _showAddExceptionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    DateTime? selectedDate;
    var isAvailable = false;
    String? startTime;
    String? endTime;
    String? reason;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final dialogTheme = Theme.of(context);
          final dialogColorScheme = dialogTheme.colorScheme;

          return AlertDialog(
            backgroundColor: dialogColorScheme.surface,
            title: Text(
              'Add Exception',
              style: dialogTheme.textTheme.titleLarge?.copyWith(
                color: dialogColorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.calendar_month,
                      color: dialogColorScheme.primary,
                    ),
                    title: Text(
                      selectedDate != null
                          ? DateFormat('EEE, MMM d, yyyy').format(selectedDate!)
                          : 'Select Date',
                      style: dialogTheme.textTheme.bodyLarge?.copyWith(
                        color: selectedDate != null
                            ? dialogColorScheme.onSurface
                            : dialogColorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Available switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Available with special hours',
                      style: dialogTheme.textTheme.bodyLarge?.copyWith(
                        color: dialogColorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Toggle off for day off',
                      style: dialogTheme.textTheme.bodySmall?.copyWith(
                        color: dialogColorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: isAvailable,
                    onChanged: (value) {
                      setState(() {
                        isAvailable = value;
                        if (!value) {
                          startTime = null;
                          endTime = null;
                        }
                      });
                    },
                  ),

                // Time fields (if available)
                if (isAvailable) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            hintText: '09:00',
                          ),
                          onChanged: (v) => startTime = v,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            hintText: '17:00',
                          ),
                          onChanged: (v) => endTime = v,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                  // Reason
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                      hintText: 'e.g., Annual leave',
                    ),
                    onChanged: (v) => reason = v.isEmpty ? null : v,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selectedDate != null
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && selectedDate != null) {
      await ref.read(exceptionsNotifierProvider.notifier).createException(
            date: selectedDate!,
            isAvailable: isAvailable,
            startTime: startTime,
            endTime: endTime,
            reason: reason,
          );
    }
  }
}

class _ExceptionCard extends StatelessWidget {
  const _ExceptionCard({
    required this.exception,
    required this.dateFormat,
    required this.onDelete,
  });

  final AvailabilityException exception;
  final DateFormat dateFormat;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: exception.isAvailable
                    ? colorScheme.primaryContainer
                    : colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                exception.isAvailable ? Icons.schedule : Icons.block,
                color: exception.isAvailable
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(exception.date),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (exception.isAvailable &&
                      exception.startTime != null &&
                      exception.endTime != null)
                    Text(
                      '${exception.startTime} - ${exception.endTime}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Text(
                      'Day off',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  if (exception.reason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      exception.reason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}
