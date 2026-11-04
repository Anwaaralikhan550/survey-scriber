import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/booking.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart'
    show liveBookingCountsProvider, weekBookingCountsProvider;
import '../providers/scheduling_providers.dart';

/// Combined Create-Booking screen.
///
/// App-Edit brief: "You cannot have Create Bookings and Select Survey type.
/// You need to combine this" — so the survey type (Home Survey / Valuation) is
/// chosen here at the top of a single booking form, replacing the separate
/// "Select Survey Type" step. The same form edits a booking when [booking] is set.
class CreateBookingPage extends ConsumerStatefulWidget {
  const CreateBookingPage({
    super.key,
    this.date,
    this.startTime,
    this.endTime,
    this.initialSurveyType = BookingSurveyType.homeSurvey,
    this.booking,
  });

  /// The booking being edited.
  final Booking? booking;

  /// Survey type pre-selected when the form opens (the segment chosen on Home).
  final BookingSurveyType initialSurveyType;
  final DateTime? date;
  final String? startTime;
  final String? endTime;

  @override
  ConsumerState<CreateBookingPage> createState() => _CreateBookingPageState();
}

/// The server's reason for refusing, without the exception name.
String? serverMessageOf(Object error) => switch (error) {
      ValidationException(:final message) => message,
      ServerException(:final message) => message,
      NetworkException(:final message) => message,
      UnauthorizedException(:final message) => message,
      _ => null,
    };

final _ukPostcode = RegExp(
  r'^[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2}$',
  caseSensitive: false,
);

/// The estate agent's address is stored as one value, one part per line, with
/// empty parts left out: Address Line, City, Postcode, County. Reads it back into
/// the form's fields. A part left out moves the others up, so the postcode is
/// found by its shape.
({String line, String city, String postcode, String county}) splitAgentAddress(
  String? stored,
) {
  final parts = (stored ?? '')
      .split('\n')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  final at = parts.indexWhere(_ukPostcode.hasMatch);
  if (at < 0) {
    return (
      line: parts.isNotEmpty ? parts[0] : '',
      city: parts.length > 1 ? parts[1] : '',
      postcode: parts.length > 2 ? parts[2] : '',
      county: parts.length > 3 ? parts.sublist(3).join(', ') : '',
    );
  }
  final before = parts.sublist(0, at);
  return (
    line: before.isNotEmpty ? before[0] : '',
    city: before.length > 1 ? before.sublist(1).join(', ') : '',
    postcode: parts[at],
    county: parts.sublist(at + 1).join(', '),
  );
}

class _CreateBookingPageState extends ConsumerState<CreateBookingPage> {
  final _formKey = GlobalKey<FormState>();

  final _jobRefController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _townController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _countyController = TextEditingController();
  final _notesController = TextEditingController();
  final _agentNameController = TextEditingController();
  final _agentPhoneController = TextEditingController();
  final _agentAddressLineController = TextEditingController();
  final _agentCityController = TextEditingController();
  final _agentPostcodeController = TextEditingController();
  final _agentCountyController = TextEditingController();
  final _agentNotesController = TextEditingController();

  static const _propertyTypes = ['House', 'Flat', 'Bungalow', 'Other'];

  late BookingSurveyType _surveyType;
  String? _propertyType;
  BookingAccessType _accessType = BookingAccessType.directAccess;

  late DateTime _selectedDate;
  late String _startTime;
  late String _endTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final booking = widget.booking;
    if (booking != null) {
      _fillFrom(booking);
      return;
    }
    _surveyType = widget.initialSurveyType;
    _selectedDate = widget.date ?? DateTime.now();
    _startTime = widget.startTime ?? '09:00';
    _endTime = widget.endTime ?? '10:00';
  }

  void _fillFrom(Booking booking) {
    _surveyType = booking.surveyType;
    _selectedDate = booking.date;
    _startTime = booking.startTime;
    _endTime = booking.endTime;
    _propertyType = booking.propertyType;
    _accessType = booking.accessType ?? BookingAccessType.directAccess;
    _jobRefController.text = booking.jobRef ?? '';
    _clientNameController.text = booking.clientName ?? '';
    _clientPhoneController.text = booking.clientPhone ?? '';
    _clientEmailController.text = booking.clientEmail ?? '';
    _yearBuiltController.text = booking.yearBuilt ?? '';
    _cityController.text = booking.city ?? '';
    _townController.text = booking.town ?? '';
    _postcodeController.text = booking.postcode ?? '';
    _countyController.text = booking.county ?? '';
    _notesController.text = booking.notes ?? '';
    // A booking from before the address was split has only the one line.
    _addressLineController.text =
        booking.addressLine ?? booking.propertyAddress ?? '';
    _agentNameController.text = booking.estateAgentName ?? '';
    _agentPhoneController.text = booking.estateAgentPhone ?? '';
    _agentNotesController.text = booking.estateAgentNotes ?? '';
    final agent = splitAgentAddress(booking.estateAgentAddress);
    _agentAddressLineController.text = agent.line;
    _agentCityController.text = agent.city;
    _agentPostcodeController.text = agent.postcode;
    _agentCountyController.text = agent.county;
  }

  @override
  void dispose() {
    for (final c in [
      _jobRefController,
      _clientNameController,
      _clientPhoneController,
      _clientEmailController,
      _yearBuiltController,
      _addressLineController,
      _cityController,
      _townController,
      _postcodeController,
      _countyController,
      _notesController,
      _agentNameController,
      _agentPhoneController,
      _agentAddressLineController,
      _agentCityController,
      _agentPostcodeController,
      _agentCountyController,
      _agentNotesController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final earliest = DateTime(today.year - 1);
    final latest = DateTime(today.year + 3);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      // An old booking keeps its own date within reach.
      firstDate: _selectedDate.isBefore(earliest) ? _selectedDate : earliest,
      lastDate: _selectedDate.isAfter(latest) ? _selectedDate : latest,
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  TimeOfDay _parseTime(String hhmm) {
    final p = hhmm.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(start ? _startTime : _endTime),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _startTime = _formatTime(picked);
        // keep a valid range: end follows start by one hour when it would be before/equal to it
        if (_formatTime(_parseTime(_endTime)).compareTo(_startTime) <= 0) {
          _endTime = _formatTime(
              TimeOfDay(hour: (picked.hour + 1) % 24, minute: picked.minute));
        }
      } else {
        _endTime = _formatTime(picked);
      }
    });
  }

  String? _trim(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    // Compose the legacy single-line address from the structured parts so the
    // rest of the app that still reads propertyAddress keeps working.
    // Compose in the App-Edit PDF display order: Address Line, City, Town,
    // County, Postcode.
    final composedAddress = [
      _trim(_addressLineController),
      _trim(_cityController),
      _trim(_townController),
      _trim(_countyController),
      _trim(_postcodeController),
    ].whereType<String>().join(', ');

    // Estate-agent address: Address Line, City, Postcode, County (PDF order), stored as
    // one value with one part per line.
    final agentAddress = [
      _trim(_agentAddressLineController),
      _trim(_agentCityController),
      _trim(_agentPostcodeController),
      _trim(_agentCountyController),
    ].whereType<String>().join('\n');

    final isCollectKeys = _accessType == BookingAccessType.collectKeys;
    final address = composedAddress.isEmpty ? null : composedAddress;
    final agentName = isCollectKeys ? _trim(_agentNameController) : null;
    final agentPhone = isCollectKeys ? _trim(_agentPhoneController) : null;
    final agentAddressValue =
        isCollectKeys && agentAddress.isNotEmpty ? agentAddress : null;
    final agentNotes = isCollectKeys ? _trim(_agentNotesController) : null;
    final notifier = ref.read(bookingsNotifierProvider.notifier);
    final editing = widget.booking;

    try {
      if (editing != null) {
        await notifier.updateBooking(
          editing.id,
          date: _selectedDate,
          startTime: _startTime,
          endTime: _endTime,
          surveyType: _surveyType,
          jobRef: _trim(_jobRefController),
          clientName: _trim(_clientNameController),
          clientPhone: _trim(_clientPhoneController),
          clientEmail: _trim(_clientEmailController),
          propertyType: _propertyType,
          yearBuilt: _trim(_yearBuiltController),
          propertyAddress: address,
          addressLine: _trim(_addressLineController),
          city: _trim(_cityController),
          town: _trim(_townController),
          postcode: _trim(_postcodeController),
          county: _trim(_countyController),
          notes: _trim(_notesController),
          accessType: _accessType,
          estateAgentName: agentName,
          estateAgentPhone: agentPhone,
          estateAgentAddress: agentAddressValue,
          estateAgentNotes: agentNotes,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking updated')),
          );
          ref.invalidate(bookingDetailProvider(editing.id));
          ref.invalidate(liveBookingCountsProvider);
          ref.invalidate(weekBookingCountsProvider);
          // The inspection follows the booking.
          ref.read(syncStateProvider.notifier).pullNow();
          _leave();
        }
        return;
      }

      final booking = await notifier.createBooking(
        surveyorId: user.id,
        date: _selectedDate,
        startTime: _startTime,
        endTime: _endTime,
        surveyType: _surveyType,
        jobRef: _trim(_jobRefController),
        clientName: _trim(_clientNameController),
        clientPhone: _trim(_clientPhoneController),
        clientEmail: _trim(_clientEmailController),
        propertyType: _propertyType,
        yearBuilt: _trim(_yearBuiltController),
        propertyAddress: address,
        addressLine: _trim(_addressLineController),
        city: _trim(_cityController),
        town: _trim(_townController),
        postcode: _trim(_postcodeController),
        county: _trim(_countyController),
        notes: _trim(_notesController),
        accessType: _accessType,
        estateAgentName: agentName,
        estateAgentPhone: agentPhone,
        estateAgentAddress: agentAddressValue,
        estateAgentNotes: agentNotes,
      );

      if (mounted && booking != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Booking created. Its inspection is in Survey Folder under Live.',
            ),
          ),
        );
        ref.invalidate(liveBookingCountsProvider);
        ref.invalidate(weekBookingCountsProvider);
        // Brings the booking's new inspection to this phone.
        ref.read(syncStateProvider.notifier).pullNow();
        _leave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_bookingErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.dashboard);
    }
  }

  /// The server's reason for refusing the booking, without the exception name.
  String _bookingErrorMessage(Object error) {
    return serverMessageOf(error) ??
        (widget.booking == null
            ? 'The booking could not be created. Please try again.'
            : 'The booking could not be saved. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final isCollectKeys = _accessType == BookingAccessType.collectKeys;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        title: Text(
          widget.booking == null ? 'Create Booking' : 'Edit Booking',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Survey type — the combined "Select Survey Type" step.
            _sectionLabel(theme, 'Survey Type'),
            const SizedBox(height: 8),
            SegmentedButton<BookingSurveyType>(
              segments: const [
                ButtonSegment(
                  value: BookingSurveyType.homeSurvey,
                  label: Text('Home Survey'),
                  icon: Icon(Icons.home_work_outlined),
                ),
                ButtonSegment(
                  value: BookingSurveyType.valuation,
                  label: Text('Valuation'),
                  icon: Icon(Icons.request_quote_outlined),
                ),
              ],
              selected: {_surveyType},
              onSelectionChanged: (s) =>
                  setState(() => _surveyType = s.first),
            ),

            const SizedBox(height: 24),

            // Appointment date/time (carried from the slot picker).
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      key: const ValueKey('pick-date'),
                      onTap: _pickDate,
                      child: _iconRow(theme, colorScheme, Icons.calendar_month,
                          dateFormat.format(_selectedDate)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            key: const ValueKey('pick-start'),
                            onTap: () => _pickTime(start: true),
                            child: _iconRow(theme, colorScheme,
                                Icons.access_time, _startTime),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            key: const ValueKey('pick-end'),
                            onTap: () => _pickTime(start: false),
                            child: _iconRow(theme, colorScheme,
                                Icons.access_time_filled, _endTime),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            _sectionLabel(theme, 'Job & Client'),
            const SizedBox(height: 16),
            _field(_jobRefController, 'Job Ref No.', Icons.tag),
            const SizedBox(height: 16),
            _field(_clientNameController, 'Client Name', Icons.person,
                caps: TextCapitalization.words),
            const SizedBox(height: 16),
            _field(_clientPhoneController, 'Phone Number', Icons.phone,
                keyboard: TextInputType.phone),
            const SizedBox(height: 16),
            _field(_clientEmailController, 'Email Address (optional)',
                Icons.email,
                keyboard: TextInputType.emailAddress, validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final r = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!r.hasMatch(value.trim())) return 'Please enter a valid email';
              }
              return null;
            }),

            const SizedBox(height: 24),

            _sectionLabel(theme, 'Property'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _propertyType,
              decoration: const InputDecoration(
                labelText: 'Property Type',
                prefixIcon: Icon(Icons.house_outlined),
              ),
              items: {..._propertyTypes, if (_propertyType != null) _propertyType!}
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _propertyType = v),
            ),
            const SizedBox(height: 16),
            _field(_yearBuiltController, 'Year Built', Icons.event,
                keyboard: TextInputType.number),
            const SizedBox(height: 16),
            _field(_addressLineController, 'Address Line', Icons.location_on,
                caps: TextCapitalization.words),
            const SizedBox(height: 16),
            _field(_cityController, 'City', Icons.location_city,
                caps: TextCapitalization.words),
            const SizedBox(height: 16),
            _field(_townController, 'Town', Icons.location_city_outlined,
                caps: TextCapitalization.words),
            const SizedBox(height: 16),
            _field(_postcodeController, 'Postcode', Icons.markunread_mailbox,
                caps: TextCapitalization.characters),
            const SizedBox(height: 16),
            _field(_countyController, 'County', Icons.map_outlined,
                caps: TextCapitalization.words),
            const SizedBox(height: 16),
            _field(_notesController, "Client's Notes", Icons.notes,
                maxLines: 3),

            const SizedBox(height: 24),

            _sectionLabel(theme, 'Access'),
            const SizedBox(height: 8),
            SegmentedButton<BookingAccessType>(
              segments: const [
                ButtonSegment(
                  value: BookingAccessType.directAccess,
                  label: Text('Direct Access'),
                  icon: Icon(Icons.meeting_room_outlined),
                ),
                ButtonSegment(
                  value: BookingAccessType.collectKeys,
                  label: Text('Collect Keys'),
                  icon: Icon(Icons.vpn_key_outlined),
                ),
              ],
              selected: {_accessType},
              onSelectionChanged: (s) => setState(() => _accessType = s.first),
            ),

            // Estate agent block — only when keys are collected.
            if (isCollectKeys) ...[
              const SizedBox(height: 20),
              _sectionLabel(theme, 'Estate Agent'),
              const SizedBox(height: 16),
              _field(_agentNameController, 'Estate Agent Name', Icons.business,
                  caps: TextCapitalization.words),
              const SizedBox(height: 16),
              _field(_agentPhoneController, 'Phone Number', Icons.phone,
                  keyboard: TextInputType.phone),
              const SizedBox(height: 16),
              _field(_agentAddressLineController, 'Address Line',
                  Icons.location_on,
                  caps: TextCapitalization.words),
              const SizedBox(height: 16),
              _field(_agentCityController, 'City', Icons.location_city,
                  caps: TextCapitalization.words),
              const SizedBox(height: 16),
              _field(_agentPostcodeController, 'Postcode',
                  Icons.markunread_mailbox,
                  caps: TextCapitalization.characters),
              const SizedBox(height: 16),
              _field(_agentCountyController, 'County', Icons.map_outlined,
                  caps: TextCapitalization.words),
              const SizedBox(height: 16),
              _field(_agentNotesController, "Agent's Notes", Icons.notes,
                  maxLines: 2),
            ] else ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Direct access — no further information required.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(switch ((widget.booking != null, _isSubmitting)) {
                  (false, false) => 'Create Booking',
                  (false, true) => 'Creating...',
                  (true, false) => 'Save Changes',
                  (true, true) => 'Saving...',
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _iconRow(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String text,
  ) =>
      Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    TextCapitalization caps = TextCapitalization.none,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          alignLabelWithHint: maxLines > 1,
        ),
        keyboardType: keyboard,
        textCapitalization: caps,
        maxLines: maxLines,
        validator: validator,
      );
}
