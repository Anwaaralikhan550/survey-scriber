import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/booking.dart';
import '../providers/scheduling_providers.dart';

/// Combined Create-Booking screen.
///
/// App-Edit brief: "You cannot have Create Bookings and Select Survey type.
/// You need to combine this" — so the survey type (Home Survey / Valuation) is
/// chosen here at the top of a single booking form, replacing the separate
/// "Select Survey Type" step.
class CreateBookingPage extends ConsumerStatefulWidget {
  const CreateBookingPage({
    super.key,
    this.date,
    this.startTime,
    this.endTime,
  });

  final DateTime? date;
  final String? startTime;
  final String? endTime;

  @override
  ConsumerState<CreateBookingPage> createState() => _CreateBookingPageState();
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
  final _agentAddressController = TextEditingController();
  final _agentNotesController = TextEditingController();

  static const _propertyTypes = ['House', 'Flat', 'Bungalow', 'Other'];

  BookingSurveyType _surveyType = BookingSurveyType.homeSurvey;
  String? _propertyType;
  BookingAccessType _accessType = BookingAccessType.directAccess;

  late DateTime _selectedDate;
  late String _startTime;
  late String _endTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date ?? DateTime.now();
    _startTime = widget.startTime ?? '09:00';
    _endTime = widget.endTime ?? '10:00';
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
      _agentAddressController,
      _agentNotesController,
    ]) {
      c.dispose();
    }
    super.dispose();
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
    final composedAddress = [
      _trim(_addressLineController),
      _trim(_cityController),
      _trim(_townController),
      _trim(_postcodeController),
      _trim(_countyController),
    ].whereType<String>().join(', ');

    try {
      final booking =
          await ref.read(bookingsNotifierProvider.notifier).createBooking(
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
                propertyAddress:
                    composedAddress.isEmpty ? null : composedAddress,
                addressLine: _trim(_addressLineController),
                city: _trim(_cityController),
                town: _trim(_townController),
                postcode: _trim(_postcodeController),
                county: _trim(_countyController),
                notes: _trim(_notesController),
                accessType: _accessType,
                estateAgentName: _accessType == BookingAccessType.collectKeys
                    ? _trim(_agentNameController)
                    : null,
                estateAgentPhone: _accessType == BookingAccessType.collectKeys
                    ? _trim(_agentPhoneController)
                    : null,
                estateAgentAddress: _accessType == BookingAccessType.collectKeys
                    ? _trim(_agentAddressController)
                    : null,
                estateAgentNotes: _accessType == BookingAccessType.collectKeys
                    ? _trim(_agentNotesController)
                    : null,
              );

      if (mounted && booking != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
          'Create Booking',
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
                    _iconRow(theme, colorScheme, Icons.calendar_month,
                        dateFormat.format(_selectedDate)),
                    const SizedBox(height: 12),
                    _iconRow(theme, colorScheme, Icons.access_time,
                        '$_startTime - $_endTime'),
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
              items: _propertyTypes
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
              _field(_agentAddressController, 'Address', Icons.location_on,
                  caps: TextCapitalization.words, maxLines: 2),
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
                label: Text(_isSubmitting ? 'Creating...' : 'Create Booking'),
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
