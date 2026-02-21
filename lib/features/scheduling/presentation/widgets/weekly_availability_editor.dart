import 'package:flutter/material.dart';

import '../../domain/entities/availability.dart';

class DayAvailabilityRow {
  DayAvailabilityRow({
    required this.dayOfWeek,
    required this.isEnabled,
    required this.startTime,
    required this.endTime,
  });

  factory DayAvailabilityRow.fromEntity(Availability availability) => DayAvailabilityRow(
      dayOfWeek: availability.dayOfWeek,
      isEnabled: availability.isActive,
      startTime: _parseTime(availability.startTime),
      endTime: _parseTime(availability.endTime),
    );

  factory DayAvailabilityRow.defaultFor(int dayOfWeek) {
    // Default: Mon-Fri 9-17, Sat-Sun disabled
    final isWeekday = dayOfWeek >= 1 && dayOfWeek <= 5;
    return DayAvailabilityRow(
      dayOfWeek: dayOfWeek,
      isEnabled: isWeekday,
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 17, minute: 0),
    );
  }

  final int dayOfWeek;
  bool isEnabled;
  TimeOfDay startTime;
  TimeOfDay endTime;

  String get dayName {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[dayOfWeek];
  }

  String get shortDayName {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dayOfWeek];
  }

  DayAvailabilityInput toInput() => DayAvailabilityInput(
      dayOfWeek: dayOfWeek,
      startTime: _formatTime(startTime),
      endTime: _formatTime(endTime),
      isActive: isEnabled,
    );

  static String _formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

class WeeklyAvailabilityEditor extends StatefulWidget {
  const WeeklyAvailabilityEditor({
    super.key,
    required this.availability,
    required this.onSave,
    this.isLoading = false,
  });

  final List<Availability> availability;
  final Future<void> Function(List<DayAvailabilityInput>) onSave;
  final bool isLoading;

  @override
  State<WeeklyAvailabilityEditor> createState() =>
      _WeeklyAvailabilityEditorState();
}

class _WeeklyAvailabilityEditorState extends State<WeeklyAvailabilityEditor> {
  late List<DayAvailabilityRow> _days;
  bool _isSaving = false;
  bool _hasLocalChanges = false; // Track if user made local edits

  @override
  void initState() {
    super.initState();
    _initDays();
  }

  @override
  void didUpdateWidget(covariant WeeklyAvailabilityEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reinitialize if availability changed AND we don't have unsaved local changes
    // This prevents the state from reverting after a successful save
    if (oldWidget.availability != widget.availability && !_hasLocalChanges) {
      _initDays();
    }
    // Reset the flag after save completes (loading goes from true to false)
    if (oldWidget.isLoading && !widget.isLoading) {
      _hasLocalChanges = false;
    }
  }

  void _initDays() {
    // Create a map of existing availability
    final existingMap = <int, Availability>{};
    for (final a in widget.availability) {
      existingMap[a.dayOfWeek] = a;
    }

    // Create rows for all 7 days
    _days = List.generate(7, (i) {
      if (existingMap.containsKey(i)) {
        return DayAvailabilityRow.fromEntity(existingMap[i]!);
      }
      return DayAvailabilityRow.defaultFor(i);
    });
  }

  Future<void> _pickTime(DayAvailabilityRow day, bool isStart) async {
    final initialTime = isStart ? day.startTime : day.endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
    );

    if (picked != null) {
      setState(() {
        _hasLocalChanges = true; // Mark as modified
        if (isStart) {
          day.startTime = picked;
        } else {
          day.endTime = picked;
        }
      });
    }
  }

  void _toggleDay(DayAvailabilityRow day, bool enabled) {
    setState(() {
      _hasLocalChanges = true; // Mark as modified
      day.isEnabled = enabled;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final inputs = _days
          .where((d) => d.isEnabled)
          .map((d) => d.toInput())
          .toList();
      await widget.onSave(inputs);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Weekly Schedule',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface, // Explicit contrast color
            ),
          ),
        ),

        // Days list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _days.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final day = _days[index];
              return _DayRow(
                day: day,
                onToggle: (enabled) => _toggleDay(day, enabled),
                onStartTimeTap: () => _pickTime(day, true),
                onEndTimeTap: () => _pickTime(day, false),
                formatTime: _formatTimeOfDay,
              );
            },
          ),
        ),

        // Save button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.isLoading || _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Availability'),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.onToggle,
    required this.onStartTimeTap,
    required this.onEndTimeTap,
    required this.formatTime,
  });

  final DayAvailabilityRow day;
  final ValueChanged<bool> onToggle;
  final VoidCallback onStartTimeTap;
  final VoidCallback onEndTimeTap;
  final String Function(TimeOfDay) formatTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Day name with toggle
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Switch(
                  value: day.isEnabled,
                  onChanged: onToggle,
                ),
                Text(
                  day.shortDayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: day.isEnabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // Time range (if enabled)
          if (day.isEnabled) ...[
            const Spacer(),
            // Start time
            InkWell(
              onTap: onStartTimeTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatTime(day.startTime),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'to',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // End time
            InkWell(
              onTap: onEndTimeTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatTime(day.endTime),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else ...[
            const Spacer(),
            Text(
              'Not available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
