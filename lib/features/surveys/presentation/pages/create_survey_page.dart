import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../providers/create_survey_provider.dart';

class CreateSurveyPage extends ConsumerWidget {
  const CreateSurveyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createSurveyProvider);
    final theme = Theme.of(context);

    ref.listen<CreateSurveyState>(createSurveyProvider, (previous, next) {
      if (next.step == CreateSurveyStep.success && next.createdSurveyId != null) {
        // Navigate to survey details — all types route through survey detail
        // which delegates to the appropriate overview page
        context.go(Routes.surveyDetailPath(next.createdSurveyId!));
      } else if (next.step == CreateSurveyStep.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.step == CreateSurveyStep.selectType
              ? 'New Survey'
              : 'Survey Details',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(createSurveyProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (state.step) {
            CreateSurveyStep.selectType => const _TypeSelectionView(key: ValueKey('type')),
            CreateSurveyStep.basicInfo => const _BasicInfoView(key: ValueKey('info')),
            CreateSurveyStep.creating => const _CreatingView(key: ValueKey('creating')),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _TypeSelectionView extends ConsumerWidget {
  const _TypeSelectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(createSurveyProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Survey Type',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the type of survey you want to create',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          _SurveyTypeCard(
            type: SurveyType.inspection,
            title: 'Property Inspection',
            description: 'Detailed property condition assessment covering construction, interior, exterior, services, and grounds.',
            icon: Icons.home_work_rounded,
            color: AppColors.primary,
            isSelected: state.surveyType == SurveyType.inspection,
            onTap: () {
              ref.read(createSurveyProvider.notifier).selectType(SurveyType.inspection);
            },
          ),
          const SizedBox(height: 14),
          _SurveyTypeCard(
            type: SurveyType.valuation,
            title: 'Property Valuation',
            description: 'Full property valuation with PID inspection, condition assessment, and valuation figures.',
            icon: Icons.real_estate_agent_rounded,
            color: AppColors.success,
            isSelected: state.surveyType == SurveyType.valuation,
            onTap: () {
              ref.read(createSurveyProvider.notifier).selectType(SurveyType.valuation);
            },
          ),
        ],
      ),
    );
  }
}

class _SurveyTypeCard extends StatelessWidget {
  const _SurveyTypeCard({
    required this.type,
    required this.title,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.pngAsset,
  }) : assert(icon != null || pngAsset != null, 'Either icon or pngAsset must be provided');

  final SurveyType type;
  final String title;
  final String description;
  final IconData? icon;
  final String? pngAsset;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title. $description${isSelected ? ', selected' : ''}',
      child: Material(
        color: isSelected
            ? color.withOpacity(0.06)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? color
                    : theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: pngAsset != null
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                color,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                pngAsset!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        : Icon(
                            icon,
                            color: color,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isSelected)
                  ExcludeSemantics(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: color,
                      size: 26,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BasicInfoView extends ConsumerStatefulWidget {
  const _BasicInfoView({super.key});

  @override
  ConsumerState<_BasicInfoView> createState() => _BasicInfoViewState();
}

class _BasicInfoViewState extends ConsumerState<_BasicInfoView> {
  final _jobRefController = TextEditingController();
  final _addressController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _countyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final state = ref.read(createSurveyProvider);
    _jobRefController.text = state.jobRef;
    _addressController.text = state.address;
    _clientNameController.text = state.clientName;
    _clientPhoneController.text = state.clientPhone;
    _yearBuiltController.text = state.yearBuilt;
    _addressLineController.text = state.addressLine;
    _cityController.text = state.city;
    _postcodeController.text = state.postcode;
    _countyController.text = state.county;
  }

  @override
  void dispose() {
    _jobRefController.dispose();
    _addressController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _yearBuiltController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _countyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(createSurveyProvider);
    final notifier = ref.read(createSurveyProvider.notifier);
    final borderRadius = BorderRadius.circular(14);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back to type selection
                  InkWell(
                    onTap: notifier.goBackToTypeSelection,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Change type',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Survey Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the details for your ${state.surveyType?.isInspection == true ? 'inspection' : 'valuation'} survey.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- Job Reference ---
                  TextFormField(
                    controller: _jobRefController,
                    decoration: InputDecoration(
                      labelText: 'Job Ref No *',
                      hintText: 'e.g., INS-2024-001',
                      prefixIcon: const Icon(Icons.tag_rounded),
                      border: OutlineInputBorder(borderRadius: borderRadius),
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: notifier.setJobRef,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Job reference is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Date & Time row ---
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: state.inspectionDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (date != null) {
                              notifier.setInspectionDate(date);
                            }
                          },
                          borderRadius: borderRadius,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Select Date',
                              border: OutlineInputBorder(borderRadius: borderRadius),
                              suffixIcon: const Icon(Icons.calendar_month_rounded),
                            ),
                            child: Text(
                              state.inspectionDate != null
                                  ? '${state.inspectionDate!.day}/${state.inspectionDate!.month}/${state.inspectionDate!.year}'
                                  : 'Select date',
                              style: state.inspectionDate != null
                                  ? theme.textTheme.bodyLarge
                                  : TextStyle(color: theme.hintColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              final formatted =
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                              notifier.setInspectionTime(formatted);
                            }
                          },
                          borderRadius: borderRadius,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Select Time',
                              border: OutlineInputBorder(borderRadius: borderRadius),
                              suffixIcon: const Icon(Icons.access_time_rounded),
                            ),
                            child: Text(
                              state.inspectionTime ?? 'Select time',
                              style: state.inspectionTime != null
                                  ? theme.textTheme.bodyLarge
                                  : TextStyle(color: theme.hintColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Property Type & Year Built row ---
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: state.propertyType.isNotEmpty ? state.propertyType : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Property Type',
                            border: OutlineInputBorder(borderRadius: borderRadius),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Detached', child: Text('Detached')),
                            DropdownMenuItem(value: 'Semi-Detached', child: Text('Semi-Detached')),
                            DropdownMenuItem(value: 'Terraced', child: Text('Terraced')),
                            DropdownMenuItem(value: 'End Terrace', child: Text('End Terrace')),
                            DropdownMenuItem(value: 'Flat/Maisonette', child: Text('Flat/Maisonette')),
                            DropdownMenuItem(value: 'Bungalow', child: Text('Bungalow')),
                            DropdownMenuItem(value: 'Cottage', child: Text('Cottage')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (value) {
                            if (value != null) notifier.setPropertyType(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _yearBuiltController,
                          decoration: InputDecoration(
                            labelText: 'Year Built',
                            hintText: 'e.g., 1990',
                            border: OutlineInputBorder(borderRadius: borderRadius),
                          ),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onChanged: notifier.setYearBuilt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Property Address (full) ---
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Property Address *',
                      hintText: 'Enter full address',
                      prefixIcon: const Icon(Icons.location_on_rounded),
                      border: OutlineInputBorder(borderRadius: borderRadius),
                    ),
                    textInputAction: TextInputAction.next,
                    maxLines: 2,
                    onChanged: notifier.setAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Address is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Address Line ---
                  TextFormField(
                    controller: _addressLineController,
                    decoration: InputDecoration(
                      labelText: 'Address Line',
                      hintText: 'Street name and number',
                      border: OutlineInputBorder(borderRadius: borderRadius),
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: notifier.setAddressLine,
                  ),
                  const SizedBox(height: 16),

                  // --- City & Postcode row ---
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'City',
                            hintText: 'City',
                            border: OutlineInputBorder(borderRadius: borderRadius),
                          ),
                          textInputAction: TextInputAction.next,
                          onChanged: notifier.setCity,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _postcodeController,
                          decoration: InputDecoration(
                            labelText: 'Postcode',
                            hintText: 'e.g. SW1A 1AA',
                            border: OutlineInputBorder(borderRadius: borderRadius),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          onChanged: notifier.setPostcode,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return null; // Optional field
                            // UK postcode regex: supports formats like A1 1AA, A11 1AA, AA1 1AA, etc.
                            final postcodeRegex = RegExp(
                              r'^[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2}$',
                              caseSensitive: false,
                            );
                            if (!postcodeRegex.hasMatch(value.trim())) {
                              return 'Enter a valid UK postcode';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- County ---
                  TextFormField(
                    controller: _countyController,
                    decoration: InputDecoration(
                      labelText: 'County',
                      hintText: 'County',
                      border: OutlineInputBorder(borderRadius: borderRadius),
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: notifier.setCounty,
                  ),
                  const SizedBox(height: 16),

                  // --- Client Name ---
                  TextFormField(
                    controller: _clientNameController,
                    decoration: InputDecoration(
                      labelText: 'Client Name',
                      hintText: 'Enter client or company name',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(borderRadius: borderRadius),
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: notifier.setClientName,
                  ),
                  const SizedBox(height: 16),

                  // --- Client Phone ---
                  TextFormField(
                    controller: _clientPhoneController,
                    decoration: InputDecoration(
                      labelText: 'Client Phone Number',
                      hintText: 'e.g. 07700 900000',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: borderRadius),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onChanged: notifier.setClientPhone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null; // Optional field
                      // Accept UK phone formats: 07xxx, +44xxx, 01xxx, 02xxx
                      final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                      if (cleaned.length < 10 || cleaned.length > 14) {
                        return 'Enter a valid phone number';
                      }
                      if (!RegExp(r'^[\+]?[0-9]+$').hasMatch(cleaned)) {
                        return 'Phone number can only contain digits, +, spaces, and dashes';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        // Bottom action bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: FilledButton(
              onPressed: state.canCreate
                  ? () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        await ref.read(createSurveyProvider.notifier).createSurvey();
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Create Survey',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreatingView extends StatelessWidget {
  const _CreatingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Creating survey...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
