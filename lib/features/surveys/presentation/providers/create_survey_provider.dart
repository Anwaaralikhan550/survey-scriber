import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/sync/sync_manager.dart';
import '../../../../core/sync/sync_state.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/domain/entities/survey_section.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../forms/presentation/providers/forms_provider.dart';
import '../../domain/repositories/survey_repository.dart';
import 'survey_providers.dart';

enum CreateSurveyStep {
  selectType,
  basicInfo,
  creating,
  success,
  error,
}

class CreateSurveyState {
  const CreateSurveyState({
    this.step = CreateSurveyStep.selectType,
    this.surveyType,
    this.jobRef = '',
    this.address = '',
    this.clientName = '',
    this.clientPhone = '',
    this.propertyType = '',
    this.yearBuilt = '',
    this.addressLine = '',
    this.city = '',
    this.postcode = '',
    this.county = '',
    this.inspectionDate,
    this.inspectionTime,
    this.createdSurveyId,
    this.errorMessage,
  });

  final CreateSurveyStep step;
  final SurveyType? surveyType;
  final String jobRef;
  final String address;
  final String clientName;
  final String clientPhone;
  final String propertyType;
  final String yearBuilt;
  final String addressLine;
  final String city;
  final String postcode;
  final String county;
  final DateTime? inspectionDate;
  final String? inspectionTime;
  final String? createdSurveyId;
  final String? errorMessage;

  bool get canProceedToBasicInfo => surveyType != null;
  bool get canCreate =>
      jobRef.trim().isNotEmpty && address.trim().isNotEmpty;

  CreateSurveyState copyWith({
    CreateSurveyStep? step,
    SurveyType? surveyType,
    String? jobRef,
    String? address,
    String? clientName,
    String? clientPhone,
    String? propertyType,
    String? yearBuilt,
    String? addressLine,
    String? city,
    String? postcode,
    String? county,
    DateTime? inspectionDate,
    String? inspectionTime,
    String? createdSurveyId,
    String? errorMessage,
  }) =>
      CreateSurveyState(
        step: step ?? this.step,
        surveyType: surveyType ?? this.surveyType,
        jobRef: jobRef ?? this.jobRef,
        address: address ?? this.address,
        clientName: clientName ?? this.clientName,
        clientPhone: clientPhone ?? this.clientPhone,
        propertyType: propertyType ?? this.propertyType,
        yearBuilt: yearBuilt ?? this.yearBuilt,
        addressLine: addressLine ?? this.addressLine,
        city: city ?? this.city,
        postcode: postcode ?? this.postcode,
        county: county ?? this.county,
        inspectionDate: inspectionDate ?? this.inspectionDate,
        inspectionTime: inspectionTime ?? this.inspectionTime,
        createdSurveyId: createdSurveyId ?? this.createdSurveyId,
        errorMessage: errorMessage,
      );
}

class CreateSurveyNotifier extends StateNotifier<CreateSurveyState> {
  CreateSurveyNotifier(this._repository, this._ref) : super(const CreateSurveyState());

  final SurveyRepository _repository;
  final Ref _ref;
  final _uuid = const Uuid();

  void selectType(SurveyType type) {
    state = state.copyWith(
      surveyType: type,
      step: CreateSurveyStep.basicInfo,
    );
  }

  void goBackToTypeSelection() {
    state = state.copyWith(step: CreateSurveyStep.selectType);
  }

  void setJobRef(String value) {
    state = state.copyWith(jobRef: value);
  }

  void setAddress(String value) {
    state = state.copyWith(address: value);
  }

  void setClientName(String value) {
    state = state.copyWith(clientName: value);
  }

  void setClientPhone(String value) {
    state = state.copyWith(clientPhone: value);
  }

  void setPropertyType(String value) {
    state = state.copyWith(propertyType: value);
  }

  void setYearBuilt(String value) {
    state = state.copyWith(yearBuilt: value);
  }

  void setAddressLine(String value) {
    state = state.copyWith(addressLine: value);
  }

  void setCity(String value) {
    state = state.copyWith(city: value);
  }

  void setPostcode(String value) {
    state = state.copyWith(postcode: value);
  }

  void setCounty(String value) {
    state = state.copyWith(county: value);
  }

  void setInspectionDate(DateTime value) {
    state = state.copyWith(inspectionDate: value);
  }

  void setInspectionTime(String value) {
    state = state.copyWith(inspectionTime: value);
  }

  Future<String?> createSurvey() async {
    if (!state.canCreate || state.surveyType == null) return null;

    state = state.copyWith(step: CreateSurveyStep.creating);

    try {
      final surveyId = _uuid.v4();
      final now = DateTime.now();

      // All survey types use the screen-based flow; no SurveySections needed.
      final sectionTemplates = <(SectionType, String)>[];

      // Create section entities (Inspection uses its own flow)
      final sections = sectionTemplates
          .asMap()
          .entries
          .map(
            (entry) => SurveySection(
              id: _uuid.v4(),
              surveyId: surveyId,
              sectionType: entry.value.$1,
              title: entry.value.$2,
              order: entry.key,
              createdAt: now,
            ),
          )
          .toList();

      // Create survey
      final survey = Survey(
        id: surveyId,
        title: _generateTitle(),
        type: state.surveyType!,
        status: SurveyStatus.draft,
        createdAt: now,
        jobRef: state.jobRef.trim(),
        address: state.address.trim(),
        clientName: state.clientName.trim().isNotEmpty
            ? state.clientName.trim()
            : null,
        totalSections: sections.length,
      );

      // Save to database
      await _repository.createSurvey(survey);
      if (sections.isNotEmpty) {
        await _repository.createSections(sections);
      }

      // Queue survey for sync to backend
      // This ensures the survey exists on the server before PDF upload
      // CRITICAL: Use toBackendString() for correct enum format (e.g., 'LEVEL_2' not 'LEVEL2')
      await _ref.read(syncStateProvider.notifier).queueSync(
        entityType: SyncEntityType.survey,
        entityId: surveyId,
        action: SyncAction.create,
        payload: {
          'title': survey.title,
          'propertyAddress': survey.address ?? '',
          'status': survey.status.toBackendString(),
          'type': survey.type.toBackendString(),
          'jobRef': survey.jobRef,
          'clientName': survey.clientName,
        },
      );

      // Invalidate list providers so they refresh with new data
      _ref.invalidate(dashboardProvider);
      _ref.invalidate(formsProvider);

      state = state.copyWith(
        step: CreateSurveyStep.success,
        createdSurveyId: surveyId,
      );

      return surveyId;
    } catch (e) {
      final message = e.toString().contains('database')
          ? 'Failed to save survey locally. Please check storage space and try again.'
          : e.toString().contains('connection') || e.toString().contains('network')
              ? 'Network error while creating survey. The survey will be saved locally and synced when online.'
              : 'Failed to create survey. Please try again.';
      state = state.copyWith(
        step: CreateSurveyStep.error,
        errorMessage: message,
      );
      return null;
    }
  }

  String _generateTitle() {
    final typeLabel = switch (state.surveyType) {
      SurveyType.valuation => 'Valuation',
      SurveyType.reinspection => 'Reinspection',
      _ => 'Inspection',
    };
    return '$typeLabel - ${state.jobRef.trim()}';
  }

  void reset() {
    state = const CreateSurveyState();
  }
}

final createSurveyProvider =
    StateNotifierProvider.autoDispose<CreateSurveyNotifier, CreateSurveyState>(
  (ref) {
    final repository = ref.watch(localSurveyRepositoryProvider);
    return CreateSurveyNotifier(repository, ref);
  },
);
