import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/sync/legacy_main_walls_sync_mapping.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/sync/sync_state.dart';
import '../../../../core/sync/v2_sync_helper.dart';
import '../../data/inspection_repository.dart';
import '../../domain/field_phrase_processor.dart';
import '../../domain/models/inspection_models.dart';
import '../../domain/inspection_phrase_engine.dart';

final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  return InspectionRepository(db, apiClient: apiClient);
});

/// Increment to force [inspectionNodesProvider] and
/// [inspectionConditionSummaryProvider] to refetch from the database.
/// This is bumped after [InspectionScreenNotifier.markComplete] so that
/// the overview badge counts and section-page checkmarks update.
final inspectionRefreshProvider = StateProvider<int>((ref) => 0);

final inspectionSectionsProvider =
    FutureProvider<List<InspectionSectionDefinition>>((ref) async {
  final repo = ref.watch(inspectionRepositoryProvider);
  return repo.getSections();
});

final inspectionNodeMapProvider =
    FutureProvider<Map<String, InspectionNodeDefinition>>((ref) async {
  final repo = ref.watch(inspectionRepositoryProvider);
  final tree = await repo.loadTree();
  final map = <String, InspectionNodeDefinition>{};
  for (final section in tree.sections) {
    for (final node in section.nodes) {
      map[node.id] = node;
    }
  }
  return map;
});

final inspectionPhraseTextsProvider =
    FutureProvider<Map<String, String>>((ref) async {
  // Check for admin-edited local override first, fall back to bundled asset.
  String raw;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final localFile = File('${dir.path}/admin/inspection_v2_phrase_texts.json');
    if (await localFile.exists()) {
      raw = await localFile.readAsString();
    } else {
      raw = await rootBundle
          .loadString('assets/property_inspection/phrase_texts.json');
    }
  } catch (e, stack) {
    debugPrint('[inspectionPhraseTextsProvider] Failed to load local override, '
        'falling back to bundled asset: $e\n$stack');
    raw = await rootBundle
        .loadString('assets/property_inspection/phrase_texts.json');
  }
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return decoded.map((key, value) => MapEntry(key, value?.toString() ?? ''));
});

final inspectionPhraseEngineProvider = Provider<InspectionPhraseEngine?>((ref) {
  final texts = ref.watch(inspectionPhraseTextsProvider);
  return texts.maybeWhen(
    data: (map) => InspectionPhraseEngine(map),
    orElse: () => null,
  );
});

final inspectionNodesProvider = FutureProvider.family.autoDispose<
    List<InspectionV2Screen>, ({String surveyId, String sectionKey})>(
  (ref, params) async {
    // Re-fetch whenever the refresh counter is bumped (e.g. after markComplete).
    ref.watch(inspectionRefreshProvider);
    final repo = ref.watch(inspectionRepositoryProvider);
    await repo.ensureSurveyInitialized(params.surveyId);
    return repo.getNodesForSection(params.surveyId, params.sectionKey);
  },
);

final inspectionConditionSummaryProvider =
    FutureProvider.family.autoDispose<Map<String, List<String>>, String>(
  (ref, surveyId) async {
    // Re-fetch whenever the refresh counter is bumped (e.g. after markComplete).
    ref.watch(inspectionRefreshProvider);
    final repo = ref.watch(inspectionRepositoryProvider);
    await repo.ensureSurveyInitialized(surveyId);
    return repo.getConditionRatingsBySection(surveyId);
  },
);

final inspectionChildScreensProvider =
    FutureProvider.family.autoDispose<List<InspectionNodeDefinition>, String>(
  (ref, parentId) async {
    final repo = ref.watch(inspectionRepositoryProvider);
    return repo.getChildScreens(parentId);
  },
);

class InspectionScreenState {
  const InspectionScreenState({
    this.isLoading = true,
    this.isSaving = false,
    this.screenDefinition,
    this.screenMeta,
    this.answers = const {},
    this.userNote = '',
    this.editedPhraseText,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final InspectionNodeDefinition? screenDefinition;
  final InspectionV2Screen? screenMeta;
  final Map<String, String> answers;
  final String userNote;

  /// When non-null, the user has manually edited the live preview text.
  /// Auto-generated phrases stop updating until the user taps "Regenerate".
  /// When null, auto-generated phrases are shown and update in real-time.
  final String? editedPhraseText;

  final String? errorMessage;

  /// Whether the preview is showing user-edited text vs auto-generated.
  bool get hasEditedPhrases => editedPhraseText != null;

  InspectionScreenState copyWith({
    bool? isLoading,
    bool? isSaving,
    InspectionNodeDefinition? screenDefinition,
    InspectionV2Screen? screenMeta,
    Map<String, String>? answers,
    String? userNote,
    String? editedPhraseText,
    bool clearEditedPhraseText = false,
    String? errorMessage,
  }) {
    return InspectionScreenState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      screenDefinition: screenDefinition ?? this.screenDefinition,
      screenMeta: screenMeta ?? this.screenMeta,
      answers: answers ?? this.answers,
      userNote: userNote ?? this.userNote,
      editedPhraseText: clearEditedPhraseText
          ? null
          : (editedPhraseText ?? this.editedPhraseText),
      errorMessage: errorMessage,
    );
  }
}

class InspectionScreenNotifier extends StateNotifier<InspectionScreenState> {
  InspectionScreenNotifier(
      this._repo, this._ref, this._surveyId, this._screenId)
      : super(const InspectionScreenState()) {
    _load();
  }

  final InspectionRepository _repo;
  final Ref _ref;
  final String _surveyId;
  final String _screenId;
  static const String _environmentImpactScreenId =
      'activity_energy_environment_impect';
  static const String _otherServiceScreenId = 'activity_other_service';
  static const String _propertyLocationScreenId = 'activity_property_location';
  static const String _chimneyLocationScreenId =
      'activity_outside_property_location';
  static const String _chimneyConditionScreenId =
      'activity_outside_property_condition';
  static const String _chimneyRepairFlashingScreenId =
      'activity_outside_property_repair_flashing';
  static const String _chimneyRepairRepointingScreenId =
      'activity_outside_property_repair_chimney_repointing';
  static const String _chimneyRepairDisrepairScreenId =
      'activity_outside_property_repair_chimney_disrepair';
  static const String _chimneyRepairDishAerialScreenId =
      'activity_outside_property_repair_chimney_dish_aerial';
  static const String _chimneyRepairDishSatelliteScreenId =
      'activity_outside_property_repair_chimney_dish_aerial__satellite';
  static const String _chimneyWaterproofingScreenId =
      'activity_outside_property_water_proofing';
  static const String _roofCoveringWeatherScreenId =
      'outside_property_roof_covering_weather_layout';
  static const String _roofCoveringConditionScreenId =
      'outside_property_roof_covering_weathered_layout';
  static const String _roofCoveringFlashingScreenId =
      'outside_property_roof_covering_flashing_layout';
  static const String _roofCoveringRidgeTilesScreenId =
      'outside_property_roof_covering_ridge_tiles_layout';
  static const String _roofCoveringHipTilesScreenId =
      'outside_property_roof_covering_hip_tiles_layout';
  static const String _roofCoveringParapetWallScreenId =
      'outside_property_roof_covering_parapet_wall_layout';
  static const String _roofCoveringDeflectionScreenId =
      'outside_property_roof_covering_deflection_layout';
  static const String _roofCoveringAsbestosScreenId =
      'outside_property_roof_covering_asbestos_layout';
  static const String _roofCoveringRoofStructureScreenId =
      'outside_property_roof_covering_roof_structure_layout';
  static const String _roofRepairTilesScreenId =
      'activity_outside_property_roof_repair_tiles';
  static const String _roofSpreadingRepairScreenId =
      'activity_outside_property_roof_spreading_repair';
  static const String _roofRepairFlatRoofScreenId =
      'activity_outside_property_roof_repair_flat_roof';
  static const String _roofRepairParapetWallScreenId =
      'activity_outside_property_roof_repair_parapet_wall';
  static const String _roofRepairVergeScreenId =
      'activity_outside_property_roof_repair_verge';
  static const String _roofRepairValleyGuttersScreenId =
      'activity_outside_property_roof_repair_valley_gutters';
  static const String _rwgWeatherConditionScreenId =
      'activity_rwg_weather_condition';
  static const String _rwgAboutScreenId = 'activity_outside_property_rwg_about';
  static const String _rwgBlockedScreenId =
      'activity_outside_property_rwg_blocked_rwg';
  static const String _rwgBlockedGulliesScreenId =
      'activity_outside_property_rwg_blocked_gullies';
  static const String _rwgOpenRunoffsScreenId =
      'activity_outside_property_rwg_open_runoffs';
  static const String _rwgRepairsScreenId =
      'activity_outside_property_rwg__repair_pipes_gutters';
  static const String _rwgNotInspectedScreenId =
      'activity_outside_property_rain_water_goods_not_inspected';
  static const String _mainWallsCladdingScreenId =
      'activity_outside_property_main_walls_cladding';
  static const String _mainWallsDpcScreenId =
      'activity_outside_property_main_walls_dpc';
  static const String _mainWallsDampScreenId =
      'activity_outside_property_main_walls_damp';
  static const String _mainWallsRemovedWallScreenId =
      'activity_outside_property_main_walls_removed_wall';
  static const String _mainWallsMovementsScreenId =
      'activity_outside_property_main_walls_movements';
  static const String _mainWallRepairThinSlimScreenId =
      'activity_outside_property_main_wall_repairs_thin_slim_wall';
  static const String _mainWallRepairWallTieScreenId =
      'activity_outside_property_main_wall_repairs_wall_the_repair';
  static const String _mainWallRepairCavityInsulationScreenId =
      'activity_outside_property_main_wall_repairs_cavity_wall_insulation';
  static const String _mainWallRepairNearbyTreesScreenId =
      'activity_outside_property_main_wall_repairs_near_by_tress';
  static const String _mainWallRepairSpallingScreenId =
      'activity_outside_property_main_wall_repairs_spalling';
  static const String _mainWallRepairSpallingCausingDampScreenId =
      'activity_outside_property_main_wall_repairs_spalling__causing_damp';
  static const String _mainWallRepairRenderScreenId =
      'activity_outside_property_main_wall_repairs_render';
  static const String _mainWallRepairPointingScreenId =
      'activity_outside_property_main_wall_repairs_pointing';
  static const String _mainWallRepairLintelScreenId =
      'activity_outside_property_main_wall_repairs_lintel';
  static const String _mainWallRepairLintelDoorScreenId =
      'activity_outside_property_main_wall_repairs_lintel__door';
  static const String _mainWallRepairWindowSillsScreenId =
      'activity_outside_property_main_wall_repairs_window_sills';
  static const String _windowsAboutScreenId =
      'activity_outside_property_windows_aboutwindow';
  static const String _windowsVeluxScreenId =
      'activity_outside_property_windows_velux_window';
  static const String _windowsRepairWindowScreenId =
      'activity_outside_property_windows_repairs_repair_window';
  static const String _windowsRepairFailedGlazingScreenId =
      'activity_outside_property_windows_repairs_failed_glazing_location';
  static const String _windowsRepairNoFireEscapeScreenId =
      'activity_outside_property_windows_repairs_no_fire_escape_risk';
  static const Set<String> _outsideDoorsAboutScreenIds = <String>{
    'activity_outside_property_out_side_doors_about_doors',
    'activity_outside_property_out_side_doors_about_doors__timber',
    'activity_outside_property_out_side_doors_about_doors__steel',
    'activity_outside_property_out_side_doors_about_doors__aluminium',
    'activity_outside_property_out_side_doors_about_doors__other',
  };
  static const String _outsideDoorsRepairFailedGlazingLocationScreenId =
      'activity_outside_property_out_side_doors_repairs_failed_glazing_location';
  static const String _outsideDoorsRepairInadequateLockLocationScreenId =
      'activity_outside_property_out_side_doors_repairs_inadequate_lock_location';
  static const Set<String> _cpLocationConstructionScreenIds = <String>{
    'activity_outside_property_conservatory_porch_location_construction',
    'activity_outside_property_conservatory_porch_location_construction__location_and_construction',
  };
  static const Set<String> _cpRoofScreenIds = <String>{
    'activity_outside_property_conservatory_porch_roof',
    'activity_outside_property_conservatory_porch_roof__roof',
  };
  static const Set<String> _cpWindowsScreenIds = <String>{
    'activity_outside_property_conservatory_porch_windows',
    'activity_outside_property_conservatory_porch_windows__windows',
  };
  static const Set<String> _cpDoorsScreenIds = <String>{
    'activity_outside_property_conservatory_porch_doors',
    'activity_outside_property_conservatory_porch_doors__doors',
  };
  static const Set<String> _cpFloorScreenIds = <String>{
    'activity_outside_property_conservatory_porch_floor',
    'activity_outside_property_conservatory_porch_floor__floor',
  };
  static const Set<String> _cpSafetyGlassRatingScreenIds = <String>{
    'activity_outside_property_conservatory_porch_safety_glass_rating',
    'activity_outside_property_conservatory_porch_safety_glass_rating__safety_glass_rating',
  };
  static const Set<String> _cpFlashingScreenIds = <String>{
    'outside_property_conservatory_porch_flashing_layout',
    'outside_property_conservatory_porch_flashing_layout__roof_flashing_with_wall',
  };
  static const Set<String> _cpConditionScreenIds = <String>{
    'activity_outside_property_porch_condition',
    'activity_outside_property_porch_condition__condition',
  };
  static const Set<String> _cpRepairsScreenIds = <String>{
    'activity_outside_property_conservatory_porch_repairs',
    'activity_outside_property_conservatory_porch_repairs__walls',
    'activity_outside_property_conservatory_porch_repairs__windows',
    'activity_outside_property_conservatory_porch_repairs__door_glazing',
    'activity_outside_property_conservatory_porch_repairs__window_glazing',
    'activity_outside_property_conservatory_porch_repairs__roof_glazing',
    'activity_outside_property_conservatory_porch_repairs__floor',
    'activity_outside_property_conservatory_porch_repairs__rainwater_goods',
  };
  static const Set<String> _otherJoineryAboutScreenIds = <String>{
    'activity_outside_property_other_about_joinery_and_finishes',
    'activity_outside_property_other_about_joinery_and_finishes__other_joinery_and_finishes',
  };
  static const String _otherJoineryConditionScreenId =
      'activity_outside_property_other_joinery_finishes_condition';
  static const Set<String> _otherJoineryRepairsScreenIds = <String>{
    'activity_outside_property_other_joinery_and_finishes_repairs',
    'activity_outside_property_other_joinery_and_finishes_repairs__repairs',
  };
  static const String _otherCommunalAreaScreenId =
      'activity_outside_property_other_communal_area';
  static const Set<String> _mainWallsAboutScreenIds = <String>{
    'activity_outside_property_main_walls_about_wall',
    'activity_outside_property_main_walls_about_wall__cavity_brick_wall',
    'activity_outside_property_main_walls_about_wall__cavity_block_wall',
    'activity_outside_property_main_walls_about_wall__cavity_stud_wall',
    'activity_outside_property_main_walls_about_wall__other',
  };

  /// Answers loaded from Drift at screen open — used to determine
  /// CREATE vs UPDATE when queueing answers for sync.
  Map<String, String> _initialAnswers = {};

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final isFirstInit = await _repo.ensureSurveyInitialized(_surveyId);
      final definition = await _repo.getNodeDefinition(_screenId);
      final screenDefinition =
          definition != null && definition.type == InspectionNodeType.screen
              ? definition
              : null;
      final meta = await _repo.getScreen(_surveyId, _screenId);
      final answers = await _repo.getScreenAnswersMap(_surveyId, _screenId);

      _initialAnswers = Map<String, String>.from(answers);

      // If there are previously persisted phrases, load them as the
      // edited text so the user sees exactly what they saved last time.
      String? loadedPhraseText;
      if (meta?.phraseOutput != null && meta!.phraseOutput!.isNotEmpty) {
        try {
          final decoded = jsonDecode(meta.phraseOutput!) as List<dynamic>;
          final phrases = decoded.cast<String>();
          if (phrases.isNotEmpty) {
            loadedPhraseText = phrases.join('\n\n');
          }
        } catch (_) {}
      }

      state = state.copyWith(
        isLoading: false,
        screenDefinition: screenDefinition,
        screenMeta: meta,
        answers: answers,
        userNote: meta?.userNote ?? '',
        editedPhraseText: loadedPhraseText,
      );

      // Queue V2 section CREATEs on first survey initialization so the
      // backend has parent Section records before any answers arrive.
      if (isFirstInit) {
        await _queueV2SectionsForSync();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load screen: $e',
      );
    }
  }

  void setAnswer(String fieldKey, String value) {
    final updated = Map<String, String>.from(state.answers);
    updated[fieldKey] = value;
    // Clear previously-loaded phrase text so the live preview regenerates
    // from the phrase engine with the latest answers (e.g. price-in-words).
    state = state.copyWith(answers: updated, clearEditedPhraseText: true);
  }

  void setUserNote(String note) {
    state = state.copyWith(userNote: note);
  }

  /// Called when the user manually edits the live preview text.
  void setEditedPhrases(String text) {
    state = state.copyWith(editedPhraseText: text);
  }

  /// Reset to auto-generated phrases (clears user edits).
  void resetPhrases() {
    state = state.copyWith(clearEditedPhraseText: true);
  }

  Future<bool> saveDraft() async {
    if (state.screenDefinition == null) return false;
    final validationError = _validateLegacyRequireds();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }
    state = state.copyWith(isSaving: true);
    try {
      await _repo.saveScreenAnswers(
        surveyId: _surveyId,
        screenId: _screenId,
        answers: state.answers,
      );
      await _persistPhraseOutput();
      await _persistUserNote();
      await _queueAnswersForSync();

      // Auto-mark as completed when there is at least one non-empty answer.
      // Legacy parity exception: Property Location density requires all
      // mandatory fields before the screen can be considered complete.
      final hasData = _screenId == _propertyLocationScreenId
          ? _isPropertyLocationComplete()
          : state.answers.values.any((v) => v.trim().isNotEmpty);
      if (hasData) {
        final wasCompleted = state.screenMeta?.isCompleted ?? false;
        await _repo.setScreenCompleted(
          surveyId: _surveyId,
          screenId: _screenId,
          isCompleted: true,
        );
        if (!wasCompleted) {
          _ref.read(inspectionRefreshProvider.notifier).state++;
        }
        final currentMeta = state.screenMeta;
        if (currentMeta != null && !currentMeta.isCompleted) {
          state = state.copyWith(
            screenMeta: currentMeta.copyWith(isCompleted: true),
          );
        }
      }

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state =
          state.copyWith(isSaving: false, errorMessage: 'Failed to save: $e');
      return false;
    }
  }

  Future<bool> markComplete() async {
    if (state.screenDefinition == null) return false;
    final validationError = _validateLegacyRequireds();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }
    if (_screenId == _environmentImpactScreenId) {
      final current =
          (state.answers['android_material_design_spinner'] ?? '').trim();
      final potential =
          (state.answers['android_material_design_spinner2'] ?? '').trim();
      if (current.isEmpty || potential.isEmpty) {
        state = state.copyWith(
          errorMessage:
              'Current and Potential are required for Environmental Impact.',
        );
        return false;
      }
    }
    if (_screenId == _otherServiceScreenId) {
      final hasSolarElectricity =
          (state.answers['ch1'] ?? '').trim().toLowerCase() == 'true';
      final hasSolarHotWater =
          (state.answers['ch2'] ?? '').trim().toLowerCase() == 'true';
      if (!hasSolarElectricity && !hasSolarHotWater) {
        state = state.copyWith(
          errorMessage: 'Select at least one Other Service option.',
        );
        return false;
      }
    }
    if (_screenId == _propertyLocationScreenId &&
        !_isPropertyLocationComplete()) {
      state = state.copyWith(
        errorMessage:
            'Established Area, Location Density From, and To are required.',
      );
      return false;
    }
    state = state.copyWith(isSaving: true);
    try {
      await _repo.saveScreenAnswers(
        surveyId: _surveyId,
        screenId: _screenId,
        answers: state.answers,
      );
      await _persistPhraseOutput();
      await _persistUserNote();
      await _queueAnswersForSync();
      await _repo.setScreenCompleted(
        surveyId: _surveyId,
        screenId: _screenId,
        isCompleted: true,
      );
      state = state.copyWith(isSaving: false);

      // Bump the refresh counter so that inspectionNodesProvider (overview
      // badge counts + section-page checkmarks) and
      // inspectionConditionSummaryProvider refetch from the database.
      _ref.read(inspectionRefreshProvider.notifier).state++;

      return true;
    } catch (e) {
      state = state.copyWith(
          isSaving: false, errorMessage: 'Failed to complete: $e');
      return false;
    }
  }

  bool _isPropertyLocationComplete() {
    final wellNewly =
        (state.answers['android_material_design_spinner'] ?? '').trim();
    final from =
        (state.answers['android_material_design_spinner2'] ?? '').trim();
    final to =
        (state.answers['android_material_design_spinner20'] ?? '').trim();
    return wellNewly.isNotEmpty && from.isNotEmpty && to.isNotEmpty;
  }

  String? _validateLegacyRequireds() {
    if (_mainWallsAboutScreenIds.contains(_screenId)) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';

      final wallKeys = [
        'cb_main_building',
        'cb_back_addition',
        'cb_extension',
        'cb_other_832',
      ];
      if (!wallKeys.any(isChecked)) {
        return 'Select at least one Wall option.';
      }

      final locationOtherChecked = isChecked('cb_other_832');
      final locationOtherText = (state.answers['et_other_133'] ?? '').trim();
      if (locationOtherChecked && locationOtherText.isEmpty) {
        return 'Enter Other wall location text or uncheck Other.';
      }

      final finishesOtherChecked = isChecked('cb_other_327');
      final finishesOtherText = (state.answers['et_other_444'] ?? '').trim();
      if (finishesOtherChecked && finishesOtherText.isEmpty) {
        return 'Enter Other finishes type text or uncheck Other.';
      }

      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
    }
    if (_screenId == _mainWallsCladdingScreenId) {
      final cladding = (state.answers['actv_cladding'] ?? '').trim();
      if (cladding.isEmpty) {
        return 'Select cladding.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final claddedWithKeys = [
        'cb_clay_tiles',
        'cb_timber',
        'cb_weathered_boards',
        'cb_profile_sheets',
        'cb_shingle_plates',
        'cb_compressed_flat_panels',
        'cb_insulated_cladding',
        'cb_other_927',
      ];
      if (!claddedWithKeys.any(isChecked)) {
        return 'Select at least one cladded-with option.';
      }
      final otherChecked = isChecked('cb_other_927');
      final otherText = (state.answers['et_other_709'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other cladding text or uncheck Other.';
      }
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
    }
    if (_screenId == _mainWallsDpcScreenId) {
      final status = (state.answers['actv_status'] ?? '').trim();
      if (status.isEmpty) {
        return 'Select status.';
      }

      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final normalized = status.toLowerCase();
      final isVisible = normalized == 'visible' ||
          (normalized.contains('visible') && !normalized.contains('not'));

      if (isVisible) {
        final consistKeys = [
          'cb_plastic',
          'cb_felt',
          'cb_slates',
          'cb_engineering_bricks',
          'cb_other_259',
        ];
        if (!consistKeys.any(isChecked)) {
          return 'Select DPC consist of.';
        }
        final otherChecked = isChecked('cb_other_259');
        final otherText = (state.answers['et_other_105'] ?? '').trim();
        if (otherChecked && otherText.isEmpty) {
          return 'Enter Other DPC material text or uncheck Other.';
        }
      } else {
        final notVisibleBecauseOf =
            (state.answers['actv_not_visible_because_of'] ?? '').trim();
        if (notVisibleBecauseOf.isEmpty) {
          return 'Select not visible because of.';
        }
        final consistKeys = [
          'cb_plastic_89',
          'cb_felt_73',
          'cb_slates_45',
          'cb_engineering_bricks_41',
          'cb_other_312',
        ];
        if (!consistKeys.any(isChecked)) {
          return 'Select DPC consist of.';
        }
        final otherChecked = isChecked('cb_other_312');
        final otherText = (state.answers['et_other_637'] ?? '').trim();
        if (otherChecked && otherText.isEmpty) {
          return 'Enter Other DPC material text or uncheck Other.';
        }
      }
    }
    if (_screenId == _mainWallsDampScreenId) {
      final status = (state.answers['actv_status'] ?? '').trim();
      if (status.isEmpty) {
        return 'Select status.';
      }
    }
    if (_screenId == _mainWallsRemovedWallScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final locationKeys = [
        'cb_lounge',
        'cb_kitchen',
        'cb_bedroom',
        'cb_other_1020',
      ];
      if (!locationKeys.any(isChecked)) {
        return 'Select removed wall location.';
      }
      final otherChecked = isChecked('cb_other_1020');
      final otherText = (state.answers['et_other_522'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
    }
    if (_screenId == _mainWallsMovementsScreenId) {
      final movementStatus =
          (state.answers['actv_movement_status'] ?? '').trim();
      if (movementStatus.isEmpty) {
        return 'Select movement status.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final normalized = movementStatus.toLowerCase();
      if (normalized == 'recent') {
        final wallKeys = ['cb_front', 'cb_side', 'cb_rear'];
        if (!wallKeys.any(isChecked)) {
          return 'Select wall.';
        }
        final locationKeys = [
          'cb_main_building',
          'cb_back_addition',
          'cb_extension',
          'cb_bay_window',
          'cb_other_501',
        ];
        if (!locationKeys.any(isChecked)) {
          return 'Select location.';
        }
        final otherLocationChecked = isChecked('cb_other_501');
        final otherLocationText = (state.answers['et_other_406'] ?? '').trim();
        if (otherLocationChecked && otherLocationText.isEmpty) {
          return 'Enter Other location text or uncheck Other.';
        }
        final causeKeys = [
          'cb_settlement',
          'cb_subsidence',
          'cb_point_loading',
          'cb_wall_tie_rust',
          'cb_other_682',
        ];
        if (!causeKeys.any(isChecked)) {
          return 'Select cracks potentially arising.';
        }
        final otherCauseChecked = isChecked('cb_other_682');
        final otherCauseText = (state.answers['et_other_884'] ?? '').trim();
        if (otherCauseChecked && otherCauseText.isEmpty) {
          return 'Enter Other cracks text or uncheck Other.';
        }
      } else if (normalized == 'recurrent') {
        final wallKeys = ['cb_front_48', 'cb_side_46', 'cb_rear_89'];
        if (!wallKeys.any(isChecked)) {
          return 'Select wall.';
        }
        final locationKeys = [
          'cb_main_building_92',
          'cb_back_addition_19',
          'cb_extension_45',
          'cb_bay_window_35',
          'cb_other_694',
        ];
        if (!locationKeys.any(isChecked)) {
          return 'Select location.';
        }
        final otherLocationChecked = isChecked('cb_other_694');
        final otherLocationText = (state.answers['et_other_425'] ?? '').trim();
        if (otherLocationChecked && otherLocationText.isEmpty) {
          return 'Enter Other location text or uncheck Other.';
        }
      }
    }
    if (_screenId == _mainWallRepairThinSlimScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final wallKeys = ['cb_front', 'cb_side', 'cb_rear', 'cb_other_608'];
      if (!wallKeys.any(isChecked)) {
        return 'Select wall.';
      }
      final otherWallChecked = isChecked('cb_other_608');
      final otherWallText = (state.answers['et_other_752'] ?? '').trim();
      if (otherWallChecked && otherWallText.isEmpty) {
        return 'Enter Other wall text or uncheck Other.';
      }
      final locationKeys = [
        'cb_main_building',
        'cb_back_addition',
        'cb_extension',
        'cb_bay_window',
        'cb_other_423',
      ];
      if (!locationKeys.any(isChecked)) {
        return 'Select location.';
      }
      final otherLocationChecked = isChecked('cb_other_423');
      final otherLocationText = (state.answers['et_other_883'] ?? '').trim();
      if (otherLocationChecked && otherLocationText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
    }
    if (_screenId == _mainWallRepairWallTieScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final wallKeys = ['cb_front', 'cb_side', 'cb_rear', 'cb_other_608'];
      if (!wallKeys.any(isChecked)) {
        return 'Select wall.';
      }
      final otherWallChecked = isChecked('cb_other_608');
      final otherWallText = (state.answers['et_other_752'] ?? '').trim();
      if (otherWallChecked && otherWallText.isEmpty) {
        return 'Enter Other wall text or uncheck Other.';
      }
    }
    if (_screenId == _mainWallRepairCavityInsulationScreenId) {
      final selected =
          (state.answers['cb_not_inspected'] ?? '').trim().toLowerCase() ==
              'true';
      if (!selected) {
        return 'Select Cavity Wall Insulation.';
      }
    }
    if (_screenId == _mainWallRepairNearbyTreesScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final treeSizeKeys = ['cb_small', 'cb_medium', 'cb_medium_to_large'];
      if (!treeSizeKeys.any(isChecked)) {
        return 'Select size of tree.';
      }
    }
    if (_screenId == _mainWallRepairSpallingScreenId ||
        _screenId == _mainWallRepairSpallingCausingDampScreenId) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select repair type.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isNow = condition.toLowerCase().contains('now');
      final wallKeys = isNow
          ? ['cb_front_64', 'cb_side_38', 'cb_rear_36']
          : ['cb_front', 'cb_side', 'cb_rear'];
      if (!wallKeys.any(isChecked)) {
        return 'Select wall.';
      }
      final locationKeys = isNow
          ? [
              'cb_main_building_47',
              'cb_back_addition_21',
              'cb_extension_36',
              'cb_bay_window_50',
              'cb_other_299',
            ]
          : [
              'cb_main_building',
              'cb_back_addition',
              'cb_extension',
              'cb_bay_window',
              'cb_other_344',
            ];
      if (!locationKeys.any(isChecked)) {
        return 'Select location.';
      }
      final otherKey = isNow ? 'cb_other_299' : 'cb_other_344';
      final otherTextKey = isNow ? 'et_other_455' : 'et_other_651';
      final otherChecked = isChecked(otherKey);
      final otherText = (state.answers[otherTextKey] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
    }
    if (_screenId == _mainWallRepairRenderScreenId) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select repair type.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isNow = condition.toLowerCase().contains('now');
      final wallKeys = isNow
          ? ['cb_front_62', 'cb_side_16', 'cb_rear_56']
          : ['cb_front', 'cb_side', 'cb_rear'];
      if (!wallKeys.any(isChecked)) {
        return 'Select wall.';
      }
      final locationKeys = isNow
          ? [
              'cb_main_building_87',
              'cb_back_addition_36',
              'cb_extension_15',
              'cb_bay_window_24',
              'cb_other_632',
            ]
          : [
              'cb_main_building',
              'cb_back_addition',
              'cb_extension',
              'cb_bay_window',
              'cb_other_312',
            ];
      if (!locationKeys.any(isChecked)) {
        return 'Select location.';
      }
      final locationOtherKey = isNow ? 'cb_other_632' : 'cb_other_312';
      final locationOtherTextKey = isNow ? 'et_other_430' : 'et_other_575';
      final locationOtherChecked = isChecked(locationOtherKey);
      final locationOtherText =
          (state.answers[locationOtherTextKey] ?? '').trim();
      if (locationOtherChecked && locationOtherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
      final defectKeys = isNow
          ? [
              'cb_cracked_101',
              'cb_loose_28',
              'cb_missing_in_places_44',
              'cb_other_415'
            ]
          : [
              'cb_cracked_96',
              'cb_loose_91',
              'cb_missing_in_places_63',
              'cb_other_868'
            ];
      if (!defectKeys.any(isChecked)) {
        return 'Select defect.';
      }
      final defectOtherKey = isNow ? 'cb_other_415' : 'cb_other_868';
      final defectOtherTextKey = isNow ? 'et_other_264' : 'et_other_857';
      final defectOtherChecked = isChecked(defectOtherKey);
      final defectOtherText = (state.answers[defectOtherTextKey] ?? '').trim();
      if (defectOtherChecked && defectOtherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _mainWallRepairPointingScreenId) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select repair type.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isNow = condition.toLowerCase().contains('now');
      final wallKeys = isNow
          ? ['cb_front_27', 'cb_side_17', 'cb_rear_30']
          : ['cb_front', 'cb_side', 'cb_rear'];
      if (!wallKeys.any(isChecked)) {
        return 'Select wall.';
      }
      final locationKeys = isNow
          ? [
              'cb_main_building_67',
              'cb_back_addition_32',
              'cb_extension_63',
              'cb_bay_window_86',
              'cb_other_318',
            ]
          : [
              'cb_main_building',
              'cb_back_addition',
              'cb_extension',
              'cb_bay_window',
              'cb_other_423',
            ];
      if (!locationKeys.any(isChecked)) {
        return 'Select location.';
      }
      final locationOtherKey = isNow ? 'cb_other_318' : 'cb_other_423';
      final locationOtherTextKey = isNow ? 'et_other_806' : 'et_other_883';
      final locationOtherChecked = isChecked(locationOtherKey);
      final locationOtherText =
          (state.answers[locationOtherTextKey] ?? '').trim();
      if (locationOtherChecked && locationOtherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
      final defectKeys = isNow
          ? ['cb_eroded_49', 'cb_loosened_83', 'cb_other_now']
          : ['cb_eroded', 'cb_loosened', 'cb_other_soon'];
      if (!defectKeys.any(isChecked)) {
        return 'Select defect.';
      }
      final defectOtherKey = isNow ? 'cb_other_now' : 'cb_other_soon';
      final defectOtherTextKey = isNow ? 'et_other_now' : 'et_other_soon';
      final defectOtherChecked = isChecked(defectOtherKey);
      final defectOtherText = (state.answers[defectOtherTextKey] ?? '').trim();
      if (defectOtherChecked && defectOtherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _mainWallRepairLintelScreenId ||
        _screenId == _mainWallRepairLintelDoorScreenId) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select repair type.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isNow = condition.toLowerCase().contains('now');
      final wallKeys = isNow
          ? ['cb_front_27', 'cb_side_17', 'cb_rear_30', 'cb_other_6082']
          : ['cb_front', 'cb_side', 'cb_rear', 'cb_other_608'];
      if (!wallKeys.any(isChecked)) {
        return 'Select wall.';
      }
      final wallOtherKey = isNow ? 'cb_other_6082' : 'cb_other_608';
      final wallOtherTextKey = isNow ? 'et_other_7522' : 'et_other_752';
      final wallOtherChecked = isChecked(wallOtherKey);
      final wallOtherText = (state.answers[wallOtherTextKey] ?? '').trim();
      if (wallOtherChecked && wallOtherText.isEmpty) {
        return 'Enter Other wall text or uncheck Other.';
      }
      final locationKeys = isNow
          ? [
              'cb_main_building_67',
              'cb_back_addition_32',
              'cb_extension_63',
              'cb_bay_window_86',
              'cb_other_318',
            ]
          : [
              'cb_main_building',
              'cb_back_addition',
              'cb_extension',
              'cb_bay_window',
              'cb_other_423',
            ];
      if (!locationKeys.any(isChecked)) {
        return 'Select location.';
      }
      final locationOtherKey = isNow ? 'cb_other_318' : 'cb_other_423';
      final locationOtherTextKey = isNow ? 'et_other_806' : 'et_other_883';
      final locationOtherChecked = isChecked(locationOtherKey);
      final locationOtherText =
          (state.answers[locationOtherTextKey] ?? '').trim();
      if (locationOtherChecked && locationOtherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
      final defectKeys = isNow
          ? [
              'cb_eroded_49',
              'cb_loosened_83',
              'cb_distorted_now',
              'cb_bulging_now',
              'cb_other_6083',
            ]
          : [
              'cb_eroded',
              'cb_loosened',
              'cb_distorted',
              'cb_bulging',
              'cb_other_6081',
            ];
      if (!defectKeys.any(isChecked)) {
        return 'Select defect.';
      }
      final defectOtherKey = isNow ? 'cb_other_6083' : 'cb_other_6081';
      final defectOtherTextKey = isNow ? 'et_other_7523' : 'et_other_7521';
      final defectOtherChecked = isChecked(defectOtherKey);
      final defectOtherText = (state.answers[defectOtherTextKey] ?? '').trim();
      if (defectOtherChecked && defectOtherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _mainWallRepairWindowSillsScreenId) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select repair type.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isNow = condition.toLowerCase().contains('now');
      final wallKeys = isNow
          ? ['cb_front_27', 'cb_side_17', 'cb_rear_30', 'cb_other_6082']
          : ['cb_front', 'cb_side', 'cb_rear', 'cb_other_608'];
      if (!wallKeys.any(isChecked)) {
        return 'Select wall.';
      }
      final wallOtherKey = isNow ? 'cb_other_6082' : 'cb_other_608';
      final wallOtherTextKey = isNow ? 'et_other_7522' : 'et_other_752';
      final wallOtherChecked = isChecked(wallOtherKey);
      final wallOtherText = (state.answers[wallOtherTextKey] ?? '').trim();
      if (wallOtherChecked && wallOtherText.isEmpty) {
        return 'Enter Other wall text or uncheck Other.';
      }
      final locationKeys = isNow
          ? [
              'cb_main_building_67',
              'cb_back_addition_32',
              'cb_extension_63',
              'cb_bay_window_86',
              'cb_other_318',
            ]
          : [
              'cb_main_building',
              'cb_back_addition',
              'cb_extension',
              'cb_bay_window',
              'cb_other_423',
            ];
      if (!locationKeys.any(isChecked)) {
        return 'Select location.';
      }
      final locationOtherKey = isNow ? 'cb_other_318' : 'cb_other_423';
      final locationOtherTextKey = isNow ? 'et_other_806' : 'et_other_883';
      final locationOtherChecked = isChecked(locationOtherKey);
      final locationOtherText =
          (state.answers[locationOtherTextKey] ?? '').trim();
      if (locationOtherChecked && locationOtherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
      final defectKeys = isNow
          ? [
              'cb_eroded_49',
              'cb_loosened_83',
              'cb_very_distorted_now',
              'cb_allowing_dampness_now',
              'cb_other_6083',
            ]
          : ['cb_loosened', 'cb_cracked_soon', 'cb_eroded', 'cb_other_6081'];
      if (!defectKeys.any(isChecked)) {
        return 'Select defect.';
      }
      final defectOtherKey = isNow ? 'cb_other_6083' : 'cb_other_6081';
      final defectOtherTextKey = isNow ? 'et_other_7523' : 'et_other_7521';
      final defectOtherChecked = isChecked(defectOtherKey);
      final defectOtherText = (state.answers[defectOtherTextKey] ?? '').trim();
      if (defectOtherChecked && defectOtherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _windowsAboutScreenId) {
      final madeUpOf = (state.answers['actv_made_up_of'] ?? '').trim();
      if (madeUpOf.isEmpty) {
        return 'Select made up of.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final typeKeys = [
        'cb_pvc',
        'cb_timber',
        'cb_steel',
        'cb_modern_pvc_sash',
        'cb_modern_timber_sash',
        'cb_aluminium',
        'cb_old_style_timber_sash',
        'cb_other_895',
      ];
      if (!typeKeys.any(isChecked)) {
        return 'Select type.';
      }
      final typeOtherChecked = isChecked('cb_other_895');
      final typeOtherText = (state.answers['et_other_220'] ?? '').trim();
      if (typeOtherChecked && typeOtherText.isEmpty) {
        return 'Enter Other type text or uncheck Other.';
      }
      final glazingKeys = ['cb_single', 'cb_double', 'cb_secondary'];
      if (!glazingKeys.any(isChecked)) {
        return 'Select glazing.';
      }
      final status = (state.answers['actv_status'] ?? '').trim();
      if (status.isEmpty) {
        return 'Select status.';
      }
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
    }
    if (_screenId == _windowsVeluxScreenId) {
      final type = (state.answers['actv_type'] ?? '').trim();
      if (type.isEmpty) {
        return 'Select type.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isSingle = type.toLowerCase() == 'single';
      if (isSingle) {
        final locationKeys = ['cb_loft', 'cb_extension', 'cb_other_629'];
        if (!locationKeys.any(isChecked)) {
          return 'Select location.';
        }
        final locationOtherChecked = isChecked('cb_other_629');
        final locationOtherText = (state.answers['et_other_290'] ?? '').trim();
        if (locationOtherChecked && locationOtherText.isEmpty) {
          return 'Enter Other location text or uncheck Other.';
        }
        final typeKeys = ['cb_pvc', 'cb_timber', 'cb_steel', 'cb_other_610'];
        if (!typeKeys.any(isChecked)) {
          return 'Select type.';
        }
        final typeOtherChecked = isChecked('cb_other_610');
        final typeOtherText = (state.answers['et_other_816'] ?? '').trim();
        if (typeOtherChecked && typeOtherText.isEmpty) {
          return 'Enter Other type text or uncheck Other.';
        }
        final glazingKeys = ['cb_single', 'cb_double', 'cb_secondary'];
        if (!glazingKeys.any(isChecked)) {
          return 'Select glazing.';
        }
      } else {
        final numberKeys = [
          'cb_one',
          'cb_two',
          'cb_three',
          'cb_four',
          'cb_five',
          'cb_other_814',
        ];
        if (!numberKeys.any(isChecked)) {
          return 'Select number of velux windows.';
        }
        final numberOtherChecked = isChecked('cb_other_814');
        final numberOtherText = (state.answers['et_other_196'] ?? '').trim();
        if (numberOtherChecked && numberOtherText.isEmpty) {
          return 'Enter Other number text or uncheck Other.';
        }
        final locationKeys = ['cb_loft_32', 'cb_extension_85', 'cb_other_451'];
        if (!locationKeys.any(isChecked)) {
          return 'Select location.';
        }
        final locationOtherChecked = isChecked('cb_other_451');
        final locationOtherText = (state.answers['et_other_659'] ?? '').trim();
        if (locationOtherChecked && locationOtherText.isEmpty) {
          return 'Enter Other location text or uncheck Other.';
        }
        final typeKeys = [
          'cb_pvc_24',
          'cb_timber_44',
          'cb_steel_91',
          'cb_other_975',
        ];
        if (!typeKeys.any(isChecked)) {
          return 'Select type.';
        }
        final typeOtherChecked = isChecked('cb_other_975');
        final typeOtherText = (state.answers['et_other_309'] ?? '').trim();
        if (typeOtherChecked && typeOtherText.isEmpty) {
          return 'Enter Other type text or uncheck Other.';
        }
        final glazingKeys = ['cb_single_48', 'cb_double_67', 'cb_secondary_54'];
        if (!glazingKeys.any(isChecked)) {
          return 'Select glazing.';
        }
      }
    }
    if (_screenId == _windowsRepairWindowScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final howManyKeys = ['cb_ch1', 'cb_ch2', 'cb_ch3'];
      if (!howManyKeys.any(isChecked)) {
        return 'Select how many.';
      }
      final locationKeys = [
        'cb_lounge_791',
        'cb_lounge_79',
        'cb_bedroom_35',
        'cb_kitchen_80',
        'cb_other_471',
      ];
      if (!locationKeys.any(isChecked)) {
        return 'Select location.';
      }
      final locationOtherChecked = isChecked('cb_other_471');
      final locationOtherText = (state.answers['et_other_175'] ?? '').trim();
      if (locationOtherChecked && locationOtherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
      final defectKeys = [
        'cb_have_damaged_locks_63',
        'cb_are_difficult_to_open_15',
        'cb_are_badly_worn_25',
        'cb_are_rotten_64',
        'cb_have_broken_panes_14',
        'cb_have_failed_glazing_40',
        'cb_are_in_disrepair_33',
        'cb_other_1066',
      ];
      if (!defectKeys.any(isChecked)) {
        return 'Select defect.';
      }
      final defectOtherChecked = isChecked('cb_other_1066');
      final defectOtherText = (state.answers['et_other_424'] ?? '').trim();
      if (defectOtherChecked && defectOtherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _windowsRepairFailedGlazingScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final locationKeys = [
        'cb__property',
        'cb_lounge_79',
        'cb_bedroom_35',
        'cb_kitchen_80',
        'cb_have_damaged_locks_63',
        'cb_other_471',
      ];
      if (!locationKeys.any(isChecked)) {
        return 'Select location.';
      }
      final otherChecked = isChecked('cb_other_471');
      final otherText = (state.answers['et_other_175'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
    }
    if (_screenId == _windowsRepairNoFireEscapeScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final locationKeys = [
        'cb_lounge_84',
        'cb_bedroom_43',
        'cb_study_61',
        'cb_other_175',
      ];
      if (!locationKeys.any(isChecked)) {
        return 'Select location.';
      }
      final locationOtherChecked = isChecked('cb_other_175');
      final locationOtherText = (state.answers['et_other_308'] ?? '').trim();
      if (locationOtherChecked && locationOtherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
      final defectKeys = [
        'cb_no_opening_63',
        'cb_is_too_small_23',
        'cb_is_too_small_23_no',
      ];
      if (!defectKeys.any(isChecked)) {
        return 'Select defect.';
      }
    }
    if (_outsideDoorsAboutScreenIds.contains(_screenId)) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final locationKeys = [
        'cb_main',
        'cb_rear',
        'cb_side',
        'cb_patio',
        'cb_garage',
        'cb_other_859',
      ];
      if (!locationKeys.any(isChecked)) {
        return 'Select door location.';
      }
      final locationOtherChecked = isChecked('cb_other_859');
      final locationOtherText = (state.answers['et_other_179'] ?? '').trim();
      if (locationOtherChecked && locationOtherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
      final glazingKeys = ['cb_single', 'cb_double'];
      if (!glazingKeys.any(isChecked)) {
        return 'Select glazing.';
      }
      final status = (state.answers['actv_status'] ?? '').trim();
      if (status.isEmpty) {
        return 'Select status.';
      }
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
      final securityOffered =
          (state.answers['actv_seciruty_offered'] ?? '').trim();
      if (securityOffered.isEmpty) {
        return 'Select security offered.';
      }
    }
    if (_screenId == _outsideDoorsRepairFailedGlazingLocationScreenId ||
        _screenId == _outsideDoorsRepairInadequateLockLocationScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final locationKeys = [
        'cb_main_63',
        'cb_rear_80',
        'cb_side_35',
        'cb_patio_42',
        'cb_garage_95',
        'cb_other_791',
      ];
      if (!locationKeys.any(isChecked)) {
        return 'Select location.';
      }
      final otherChecked = isChecked('cb_other_791');
      final otherText = (state.answers['et_other_129'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
    }
    if (_cpLocationConstructionScreenIds.contains(_screenId)) {
      final location = (state.answers['actv_location'] ?? '').trim();
      if (location.isEmpty) {
        return 'Select location.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final constructionKeys = [
        'cb_brick_walls',
        'cb_pvc_double_glazed_sections',
        'cb_timber_double_glazed_sections',
        'cb_other_925',
      ];
      if (!constructionKeys.any(isChecked)) {
        return 'Select construction.';
      }
      final otherConstructionChecked = isChecked('cb_other_925');
      final otherConstructionText =
          (state.answers['et_other_249'] ?? '').trim();
      if (otherConstructionChecked && otherConstructionText.isEmpty) {
        return 'Enter Other construction text or uncheck Other.';
      }
      if (_screenId ==
          'activity_outside_property_conservatory_porch_location_construction__location_and_construction') {
        final porchTypeKeys = [
          'cb_shared',
          'cb_integral',
          'cb_open',
          'cb_other_porch',
        ];
        if (!porchTypeKeys.any(isChecked)) {
          return 'Select porch type.';
        }
        final otherPorchTypeChecked = isChecked('cb_other_porch');
        final otherPorchTypeText =
            (state.answers['et_other_porch'] ?? '').trim();
        if (otherPorchTypeChecked && otherPorchTypeText.isEmpty) {
          return 'Enter Other porch type text or uncheck Other.';
        }
      }
    }
    if (_cpRoofScreenIds.contains(_screenId)) {
      final roofType = (state.answers['actv_roof_type'] ?? '').trim();
      if (roofType.isEmpty) {
        return 'Select roof type.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final materialKeys = [
        'cb_floor_above',
        'cb_pvc_double_glazed_sections',
        'cb_polycarbonate_sheets',
        'cb_concrete_tiles',
        'cb_clay_tiles',
        'cb_mineral_felt',
        'cb_lead',
        'cb_others_373',
      ];
      if (!materialKeys.any(isChecked)) {
        return 'Select material.';
      }
      final otherChecked = isChecked('cb_others_373');
      final otherText = (state.answers['et_other_403'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other material text or uncheck Other.';
      }
    }
    if (_cpWindowsScreenIds.contains(_screenId) ||
        _cpDoorsScreenIds.contains(_screenId)) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final incorporatesKeys = ['cb_single', 'cb_double'];
      if (!incorporatesKeys.any(isChecked)) {
        return 'Select incorporates.';
      }
      final glazingKeys = ['cb_pvc', 'cb_timber', 'cb_other_1047'];
      if (!glazingKeys.any(isChecked)) {
        return 'Select glazing.';
      }
      final otherChecked = isChecked('cb_other_1047');
      final otherText = (state.answers['et_other_632'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other glazing text or uncheck Other.';
      }
    }
    if (_cpFloorScreenIds.contains(_screenId)) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final floorKeys = [
        'cb_tiles',
        'cb_laminate_flooring',
        'cb_carpets',
        'cb_other_743',
      ];
      if (!floorKeys.any(isChecked)) {
        return 'Select floor covered in.';
      }
      final otherChecked = isChecked('cb_other_743');
      final otherText = (state.answers['et_other_886'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other floor text or uncheck Other.';
      }
    }
    if (_cpSafetyGlassRatingScreenIds.contains(_screenId)) {
      final status = (state.answers['actv_status'] ?? '').trim();
      if (status.isEmpty) {
        return 'Select status.';
      }
    }
    if (_cpFlashingScreenIds.contains(_screenId)) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final flashingKeys = ['cb_lead', 'cb_mortar', 'cb_tiles', 'cb_other_33'];
      if (!flashingKeys.any(isChecked)) {
        return 'Select flashing with wall.';
      }
      final otherChecked = isChecked('cb_other_33');
      final otherText = (state.answers['et_other_87'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other flashing text or uncheck Other.';
      }
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
    }
    if (_cpConditionScreenIds.contains(_screenId)) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
    }
    if (_cpRepairsScreenIds.contains(_screenId)) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isNow = condition.toLowerCase().contains('now');
      final defectKeys = isNow
          ? [
              'cb_cracked_51',
              'cb_damaged_22',
              'cb_rotten_46',
              'cb_leaking_80',
              'cb_damp_25',
              'cb_failed_89',
              'cb_misted_over_85',
              'cb_other_350',
            ]
          : [
              'cb_cracked',
              'cb_damaged',
              'cb_rotten',
              'cb_leaking',
              'cb_damp',
              'cb_failed',
              'cb_misted_over',
              'cb_other_519',
            ];
      if (!defectKeys.any(isChecked)) {
        return 'Select defect.';
      }
      final otherKey = isNow ? 'cb_other_350' : 'cb_other_519';
      final otherTextKey = isNow ? 'et_other_430' : 'et_other_346';
      final otherChecked = isChecked(otherKey);
      final otherText = (state.answers[otherTextKey] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_otherJoineryAboutScreenIds.contains(_screenId)) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final externalWorkKeys = [
        'cb_facias',
        'cb_soffits',
        'cb_bargeboards',
        'cb_verge_clips',
        'cb_other_326',
      ];
      if (!externalWorkKeys.any(isChecked)) {
        return 'Select external work.';
      }
      final externalOtherChecked = isChecked('cb_other_326');
      final externalOtherText =
          ((state.answers['et_other_397'] ?? '').trim().isNotEmpty
                  ? state.answers['et_other_397']
                  : state.answers['et_other_393']) ??
              '';
      if (externalOtherChecked && externalOtherText.trim().isEmpty) {
        return 'Enter Other external work text or uncheck Other.';
      }

      final materialKeys = ['cb_timber', 'cb_pvc', 'cb_slates', 'cb_other_397'];
      if (!materialKeys.any(isChecked)) {
        return 'Select material.';
      }
      final materialOtherChecked = isChecked('cb_other_397');
      final materialOtherText =
          ((state.answers['et_other_393'] ?? '').trim().isNotEmpty
                  ? state.answers['et_other_393']
                  : state.answers['et_other_397']) ??
              '';
      if (materialOtherChecked && materialOtherText.trim().isEmpty) {
        return 'Enter Other material text or uncheck Other.';
      }
    }
    if (_screenId == _otherJoineryConditionScreenId) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
    }
    if (_otherJoineryRepairsScreenIds.contains(_screenId)) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final itemKeys = [
        'cb_facias',
        'cb_soffits',
        'cb_barge_boards',
        'cb_verge_clips',
        'cb_timber_cladding',
        'cb_other_289',
      ];
      if (!itemKeys.any(isChecked)) {
        return 'Select item.';
      }
      final itemOtherChecked = isChecked('cb_other_289');
      final itemOtherText = (state.answers['et_other_178'] ?? '').trim();
      if (itemOtherChecked && itemOtherText.isEmpty) {
        return 'Enter Other item text or uncheck Other.';
      }

      final locationKeys = [
        'cb_main_building_86',
        'cb_back_addition_47',
        'cb_extension_25',
        'cb_bay_window_61',
        'cb_garage_21',
        'cb_other_269',
      ];
      if (!locationKeys.any(isChecked)) {
        return 'Select location.';
      }
      final locationOtherChecked = isChecked('cb_other_269');
      final locationOtherText = (state.answers['et_other_567'] ?? '').trim();
      if (locationOtherChecked && locationOtherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }

      final defectKeys = [
        'cb_rotted',
        'cb_damaged',
        'cb_poorly_secured',
        'cb_incomplete',
        'cb_other_777',
      ];
      if (!defectKeys.any(isChecked)) {
        return 'Select defect.';
      }
      final defectOtherChecked = isChecked('cb_other_777');
      final defectOtherText = (state.answers['et_other_473'] ?? '').trim();
      if (defectOtherChecked && defectOtherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _otherCommunalAreaScreenId) {
      final status = (state.answers['actv_status'] ?? '').trim();
      if (status.isEmpty) {
        return 'Select status.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isInspected = status.toLowerCase() == 'inspected';
      if (isInspected) {
        final externalKeys = [
          'cb_automatic_gates',
          'cb_cctv',
          'cb_communal_door',
          'cb_entry_system',
          'cb_drive_access',
          'cb_car_park',
          'cb_walk_paths',
          'cb_gardens',
          'cb_grounds',
          'cb_play_ground',
          'cb_other_1034',
        ];
        if (!externalKeys.any(isChecked)) {
          return 'Select external communal parts.';
        }
        final otherChecked = isChecked('cb_other_1034');
        final otherText = (state.answers['et_other_747'] ?? '').trim();
        if (otherChecked && otherText.isEmpty) {
          return 'Enter Other communal part text or uncheck Other.';
        }
      } else {
        final reasonKeys = [
          'cb_the_area_is_not_accessible',
          'cb_of_limited_access',
          'cb_other_251',
        ];
        if (!reasonKeys.any(isChecked)) {
          return 'Select reason.';
        }
        final otherChecked = isChecked('cb_other_251');
        final otherText = (state.answers['et_other_928'] ?? '').trim();
        if (otherChecked && otherText.isEmpty) {
          return 'Enter Other reason text or uncheck Other.';
        }
      }
    }

    if (_screenId == 'activity_inside_property_limitation') {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      if (isChecked('ch2')) {
        final reasonKeys = [
          'cb_statuslimited_roof_height',
          'cb_floors_not_safe_to_walk_on',
          'cb_some_or_all_of_the_floors_are_boarded',
          'cb_excessive_storage_of_personal_goods',
          'ch3',
          'ch4',
          'ch5',
          'ch6',
        ];
        if (!reasonKeys.any(isChecked)) {
          return 'Select reason.';
        }
        final otherText = (state.answers['etGroundTypeOther'] ?? '').trim();
        if (isChecked('ch6') && otherText.isEmpty) {
          return 'Enter Other reason text or uncheck Other.';
        }
      }
    }

    if (_screenId == _chimneyLocationScreenId) {
      final otherChecked =
          (state.answers['ch5'] ?? '').trim().toLowerCase() == 'true';
      final otherText = (state.answers['etGroundTypeOther'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
    }
    if (_screenId == _chimneyWaterproofingScreenId) {
      final flashingOtherChecked =
          (state.answers['ch5'] ?? '').trim().toLowerCase() == 'true';
      final flashingOtherText =
          (state.answers['etGroundTypeOther'] ?? '').trim();
      if (flashingOtherChecked && flashingOtherText.isEmpty) {
        return 'Enter Other flashing text or uncheck Other.';
      }

      final flaunchingOtherChecked =
          (state.answers['ch10'] ?? '').trim().toLowerCase() == 'true';
      final flaunchingOtherText =
          (state.answers['etFlaunchingOther'] ?? '').trim();
      if (flaunchingOtherChecked && flaunchingOtherText.isEmpty) {
        return 'Enter Other flaunching text or uncheck Other.';
      }
    }
    if (_screenId == _chimneyConditionScreenId) {
      final condition =
          (state.answers['android_material_design_spinner3'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Condition is required.';
      }
    }
    if (_screenId == _chimneyRepairFlashingScreenId) {
      final flashingType =
          (state.answers['android_material_design_spinner4'] ?? '').trim();
      if (flashingType.isEmpty) {
        return 'Select flashing repair type.';
      }

      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isSoon = flashingType.toLowerCase().contains('soon');

      final stackKeys = isSoon
          ? ['chs1', 'chs2', 'chs3', 'chs4', 'chs5']
          : ['ch1', 'ch2', 'ch3', 'ch4', 'ch5'];
      final issueKeys = isSoon
          ? ['ch10', 'ch11', 'ch12', 'ch13', 'ch14']
          : ['ch6', 'ch7', 'ch8', 'ch9'];

      final hasStack = stackKeys.any(isChecked);
      if (!hasStack) {
        return 'Select at least one Chimney option.';
      }

      final hasIssue = issueKeys.any(isChecked);
      if (!hasIssue) {
        return 'Select at least one Defect option.';
      }

      final stackOtherChecked = isChecked(isSoon ? 'chs5' : 'ch5');
      final stackOtherText = (state.answers[
                  isSoon ? 'etChimneySoonOther' : 'etChimneyCommonOther'] ??
              '')
          .trim();
      if (stackOtherChecked && stackOtherText.isEmpty) {
        return 'Enter Other chimney text or uncheck Other.';
      }

      final defectOtherChecked = isChecked(isSoon ? 'ch14' : 'ch9');
      final defectOtherText = (state.answers[isSoon
                  ? 'etRepairSoonProblemOther'
                  : 'etRepairNowProblemOther'] ??
              '')
          .trim();
      if (defectOtherChecked && defectOtherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _chimneyRepairRepointingScreenId) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select repair condition.';
      }

      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isSoon = condition.toLowerCase().contains('soon');

      final stackKeys = isSoon
          ? ['cb_main_building_25', 'cb_front_96', 'cb_side_40', 'cb_rear_32']
          : ['cb_main_building_79', 'cb_front_55', 'cb_side_79', 'cb_rear_99'];
      final issueKeys = isSoon
          ? [
              'cb_has_eroded',
              'cb_is_partly_missing',
              'cb_is_loose',
              'cb_other_669'
            ]
          : ['cb_badly_eroded', 'cb_largely_missing', 'cb_other_862'];

      if (!stackKeys.any(isChecked)) {
        return 'Select at least one Chimney Stack option.';
      }
      if (!issueKeys.any(isChecked)) {
        return 'Select at least one Defect option.';
      }

      final otherChecked = isChecked(isSoon ? 'cb_other_669' : 'cb_other_862');
      final otherText =
          (state.answers[isSoon ? 'et_other_201' : 'et_other_169'] ?? '')
              .trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _chimneyRepairDisrepairScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';

      if (!isChecked('cb_repair_soon_70')) {
        return 'Select condition.';
      }

      final stackKeys = [
        'cb_main_building_21',
        'cb_front_101',
        'cb_side_71',
        'cb_rear_16',
        'cb_other_608'
      ];
      if (!stackKeys.any(isChecked)) {
        return 'Select at least one Chimney Stack Location option.';
      }

      final otherChecked = isChecked('cb_other_608');
      final otherText = (state.answers['et_other_752'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
    }
    if (_screenId == _chimneyRepairDishAerialScreenId ||
        _screenId == _chimneyRepairDishSatelliteScreenId) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }

      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isSoon = condition.toLowerCase().contains('soon');
      final issueKeys = isSoon
          ? ['cb_loose', 'cb_rusted', 'cb_other_920']
          : ['cb_very_loose', 'cb_badly_rusted', 'cb_other_698'];
      if (!issueKeys.any(isChecked)) {
        return 'Select at least one Defect option.';
      }

      final otherChecked = isChecked(isSoon ? 'cb_other_920' : 'cb_other_698');
      final otherText =
          (state.answers[isSoon ? 'et_other_193' : 'et_other_633'] ?? '')
              .trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _roofCoveringWeatherScreenId) {
      final weather = (state.answers['actv_status'] ?? '').trim();
      if (weather.isEmpty) {
        return 'Select status.';
      }
    }
    if (_screenId == _roofCoveringConditionScreenId) {
      final weatheredChecked =
          (state.answers['cb_weathered'] ?? '').trim().toLowerCase() == 'true';
      if (!weatheredChecked) {
        return 'Select Weathered.';
      }
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
    }
    if (_screenId == _roofCoveringFlashingScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final materialKeys = ['cb_lead', 'cb_mortar', 'cb_tiles', 'cb_other_33'];
      if (!materialKeys.any(isChecked)) {
        return 'Select at least one flashing type.';
      }
      final otherChecked = isChecked('cb_other_33');
      final otherText = (state.answers['et_other_87'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other flashing text or uncheck Other.';
      }
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
    }
    if (_screenId == _roofCoveringRidgeTilesScreenId ||
        _screenId == _roofCoveringHipTilesScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final materialKeys = [
        'cb_tiles',
        'cb_lead',
        'cb_concrete',
        'cb_other_62'
      ];
      if (!materialKeys.any(isChecked)) {
        return _screenId == _roofCoveringRidgeTilesScreenId
            ? 'Select at least one Ridge Tiles option.'
            : 'Select at least one Hip Tiles option.';
      }
      final otherChecked = isChecked('cb_other_62');
      final otherText = (state.answers['et_other_101'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other material text or uncheck Other.';
      }
      final condition = (state.answers['actv_formed_in'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
    }
    if (_screenId == _roofCoveringParapetWallScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final builtWithKeys = [
        'cb_bricks',
        'cb_concrete',
        'cb_block',
        'cb_other_44'
      ];
      if (!builtWithKeys.any(isChecked)) {
        return 'Select at least one Built with option.';
      }
      final otherChecked = isChecked('cb_other_44');
      final otherText = (state.answers['et_other_101'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other built-with text or uncheck Other.';
      }
      final rendered = (state.answers['actv_rendered'] ?? '').trim();
      if (rendered.isEmpty) {
        return 'Select rendered.';
      }
      final condition =
          (state.answers['android_material_design_spinner3'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
    }
    if (_screenId == _roofCoveringDeflectionScreenId) {
      final status = (state.answers['actv_status'] ?? '').trim();
      if (status.isEmpty) {
        return 'Select status.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final locationKeys = [
        'cb_front_45',
        'cb_side_41',
        'cb_rear_47',
        'cb_other_207'
      ];
      if (!locationKeys.any(isChecked)) {
        return 'Select at least one location.';
      }
      final otherLocationChecked = isChecked('cb_other_207');
      final otherLocationText = (state.answers['et_other_822'] ?? '').trim();
      if (otherLocationChecked && otherLocationText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
      final otherReasonChecked = isChecked('cb_other_897');
      final otherReasonText = (state.answers['et_other_410'] ?? '').trim();
      if (otherReasonChecked && otherReasonText.isEmpty) {
        return 'Enter Other cause text or uncheck Other.';
      }
    }
    if (_screenId == _roofCoveringAsbestosScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final keys = [
        'cb_roof_covering',
        'cb_verge',
        'cb_soffits',
        'cb_other_654'
      ];
      if (!keys.any(isChecked)) {
        return 'Select at least one asbestos location.';
      }
      final otherChecked = isChecked('cb_other_654');
      final otherText = (state.answers['et_other_151'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other asbestos text or uncheck Other.';
      }
    }
    if (_screenId == _roofCoveringRoofStructureScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final roofOverKeys = [
        'cb_main_building_22',
        'cb_back_addition_48',
        'cb_other_230'
      ];
      if (!roofOverKeys.any(isChecked)) {
        return 'Select at least one location.';
      }
      final otherChecked = isChecked('cb_other_230');
      final otherText = (state.answers['et_other_859'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
      final status = (state.answers['actv_status'] ?? '').trim();
      if (status.isEmpty) {
        return 'Select status.';
      }
      final isInvestigate = status.toLowerCase().contains('investigate');
      if (isInvestigate) {
        final slopeKeys = ['cb_front_39', 'cb_side_78', 'cb_rear_20'];
        if (!slopeKeys.any(isChecked)) {
          return 'Select at least one roof slope.';
        }
      }
    }
    if (_screenId == _roofRepairTilesScreenId) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isSoon = condition.toLowerCase().contains('soon');
      final typeKeys = isSoon
          ? ['cb_roof_14', 'cb_ridge_64', 'cb_hip_95']
          : ['cb_roof_40', 'cb_ridge_16', 'cb_hip_42'];
      if (!typeKeys.any(isChecked)) {
        return 'Select at least one Type of tiles option.';
      }
      final defectKeys = isSoon
          ? [
              'cb_are_loose_71',
              'cb_have_slipped_19',
              'cb_are_missing_88',
              'cb_are_cracked_80',
              'cb_are_poorly_secured_51',
              'cb_are_damaged_24',
              'cb_other_195'
            ]
          : [
              'cb_are_loose_24',
              'cb_are_lifted_48',
              'cb_have_slipped_71',
              'cb_are_missing_29',
              'cb_are_cracked_50',
              'cb_are_poorly_secured_25',
              'cb_are_damaged_65',
              'cb_other_395'
            ];
      if (!defectKeys.any(isChecked)) {
        return 'Select at least one Defect option.';
      }
      final otherChecked = isChecked(isSoon ? 'cb_other_195' : 'cb_other_395');
      final otherText =
          (state.answers[isSoon ? 'et_other_903' : 'et_other_339'] ?? '')
              .trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _roofSpreadingRepairScreenId) {
      final status = (state.answers['actv_status'] ?? '').trim();
      if (status.isEmpty) {
        return 'Select status.';
      }
    }
    if (_screenId == _roofRepairFlatRoofScreenId) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isSoon = condition.toLowerCase().contains('soon');
      final keys = isSoon
          ? [
              'cb_torn',
              'cb_split',
              'cb_damaged',
              'cb_blistered',
              'cb_holding_water',
              'cb_covered_with_moss',
              'cb_other_944'
            ]
          : [
              'cb_torn_78',
              'cb_split_43',
              'cb_damaged_25',
              'cb_blistered_45',
              'cb_ponding_58',
              'cb_other_516'
            ];
      if (!keys.any(isChecked)) {
        return 'Select at least one roof repair defect.';
      }
      final otherChecked = isChecked(isSoon ? 'cb_other_944' : 'cb_other_516');
      final otherText =
          (state.answers[isSoon ? 'et_other_617' : 'et_other_928'] ?? '')
              .trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other roof repair text or uncheck Other.';
      }
    }
    if (_screenId == _roofRepairParapetWallScreenId) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isSoon = condition.toLowerCase().contains('soon');
      final subjectKeys = isSoon
          ? [
              'cb_rendering_68',
              'cb_copping_21',
              'cb_flashing_34',
              'cb_other_836'
            ]
          : [
              'cb_rendering_16',
              'cb_copping_37',
              'cb_flashing_76',
              'cb_other_390'
            ];
      if (!subjectKeys.any(isChecked)) {
        return 'Select at least one Particular option.';
      }
      final subjectOtherChecked =
          isChecked(isSoon ? 'cb_other_836' : 'cb_other_390');
      final subjectOtherText =
          (state.answers[isSoon ? 'et_other_272' : 'et_other_662'] ?? '')
              .trim();
      if (subjectOtherChecked && subjectOtherText.isEmpty) {
        return 'Enter Other particular text or uncheck Other.';
      }
      final locationKeys = isSoon
          ? ['cb_right_72', 'cb_left_59', 'cb_rear_58', 'cb_front_70']
          : [
              'cb_rendering_61',
              'cb_copping_20',
              'cb_flashing_83',
              'cb_other_705'
            ];
      if (!locationKeys.any(isChecked)) {
        return 'Select at least one Location option.';
      }
      final defectKeys = isSoon
          ? [
              'cb_damaged_94',
              'cb_loose_22',
              'cb_partly_missing_90',
              'cb_cracked_73',
              'cb_poorly_secured_94',
              'cb_other_526'
            ]
          : ['cb_badly_damaged_70', 'cb_very_loose_63', 'cb_other_239'];
      if (!defectKeys.any(isChecked)) {
        return 'Select at least one Defect option.';
      }
      final defectOtherChecked =
          isChecked(isSoon ? 'cb_other_526' : 'cb_other_239');
      final defectOtherText =
          (state.answers[isSoon ? 'et_other_730' : 'et_other_787'] ?? '')
              .trim();
      if (defectOtherChecked && defectOtherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _roofRepairVergeScreenId) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isSoon = condition.toLowerCase().contains('soon');
      final particularKeys = isSoon
          ? ['cb_mortar_58', 'cb_tiles_101', 'cb_clips_95', 'cb_other_521']
          : [
              'cb_rendering_52',
              'cb_copping_32',
              'cb_flashing_62',
              'cb_other_814'
            ];
      if (!particularKeys.any(isChecked)) {
        return 'Select at least one Particular option.';
      }
      final particularOtherChecked =
          isChecked(isSoon ? 'cb_other_521' : 'cb_other_814');
      final particularOtherText =
          (state.answers[isSoon ? 'et_other_650' : 'et_other_133'] ?? '')
              .trim();
      if (particularOtherChecked && particularOtherText.isEmpty) {
        return 'Enter Other particular text or uncheck Other.';
      }
      final defectKeys = isSoon
          ? [
              'cb_damaged_32',
              'cb_loose_25',
              'cb_partly_missing_77',
              'cb_cracked_93',
              'cb_poorly_secured_51',
              'cb_other_507'
            ]
          : [
              'cb_badly_damaged_19',
              'cb_badly_cracked_46',
              'cb_about_to_drop_36',
              'cb_other_491'
            ];
      if (!defectKeys.any(isChecked)) {
        return 'Select at least one Defect option.';
      }
      final defectOtherChecked =
          isChecked(isSoon ? 'cb_other_507' : 'cb_other_491');
      final defectOtherText =
          (state.answers[isSoon ? 'et_other_458' : 'et_other_477'] ?? '')
              .trim();
      if (defectOtherChecked && defectOtherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _roofRepairValleyGuttersScreenId) {
      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final locationKeys = [
        'cb_front_14',
        'cb_side_19',
        'cb_rear_95',
        'cb_other_6081'
      ];
      if (!locationKeys.any(isChecked)) {
        return 'Select at least one Location option.';
      }
      final locationOtherChecked = isChecked('cb_other_6081');
      final locationOtherText = (state.answers['et_other_7521'] ?? '').trim();
      if (locationOtherChecked && locationOtherText.isEmpty) {
        return 'Enter Other location text or uncheck Other.';
      }
      final statusKeys = ['cb_partially_35', 'cb_completely_78'];
      if (!statusKeys.any(isChecked)) {
        return 'Select status.';
      }
      final defectKeys = [
        'cb_blocked_with_debris_90',
        'cb_poorly_aligned_14',
        'cb_Poor_detailing',
        'cb_Detailing_damage',
        'cb_other_608'
      ];
      if (!defectKeys.any(isChecked)) {
        return 'Select at least one Defect option.';
      }
      final defectOtherChecked = isChecked('cb_other_608');
      final defectOtherText = (state.answers['et_other_752'] ?? '').trim();
      if (defectOtherChecked && defectOtherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _rwgWeatherConditionScreenId) {
      final weather = (state.answers['actv_weather_condition'] ?? '').trim();
      if (weather.isEmpty) {
        return 'Select weather condition.';
      }
    }
    if (_screenId == _rwgAboutScreenId) {
      final madeUp =
          (state.answers['actv_rainwater_goods_are_made_up'] ?? '').trim();
      if (madeUp.isEmpty) {
        return 'Select rainwater goods are made up.';
      }

      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final typeKeys = [
        'cb_plastic',
        'cb_cast_iron',
        'cb_asbestos_cement',
        'cb_concrete',
        'cb_metal',
        'cb_other_697'
      ];
      if (!typeKeys.any(isChecked)) {
        return 'Select at least one Type option.';
      }

      final otherChecked = isChecked('cb_other_697');
      final otherText = (state.answers['et_other_427'] ?? '').trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other type text or uncheck Other.';
      }

      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }
    }
    if (_screenId == _rwgBlockedScreenId) {
      final checked =
          (state.answers['cb_blocked_rwg'] ?? '').trim().toLowerCase() ==
              'true';
      if (!checked) {
        return 'Select Blocked RWG.';
      }
    }
    if (_screenId == _rwgBlockedGulliesScreenId) {
      final checked =
          (state.answers['cb_blocked_gullies'] ?? '').trim().toLowerCase() ==
              'true';
      if (!checked) {
        return 'Select Blocked gullies.';
      }
    }
    if (_screenId == _rwgOpenRunoffsScreenId) {
      final checked =
          (state.answers['cb_open_runoffs'] ?? '').trim().toLowerCase() ==
              'true';
      if (!checked) {
        return 'Select Open runoffs.';
      }
    }
    if (_screenId == _rwgRepairsScreenId) {
      final condition = (state.answers['actv_condition'] ?? '').trim();
      if (condition.isEmpty) {
        return 'Select condition.';
      }

      bool isChecked(String key) =>
          (state.answers[key] ?? '').trim().toLowerCase() == 'true';
      final isSoon = condition.toLowerCase().contains('soon');
      final itemKeys = isSoon
          ? ['cb_pipes_101', 'cb_gutters_28']
          : ['cb_pipes_96', 'cb_gutters_59'];
      if (!itemKeys.any(isChecked)) {
        return 'Select at least one Item option.';
      }

      final defectKeys = isSoon
          ? [
              'cb_are_leaking_78',
              'cb_are_loose_39',
              'cb_are_incomplete_52',
              'cb_are_blocked_101',
              'cb_are_rusted_26',
              'cb_do_not_have_sufficient_slope_53',
              'cb_other_458'
            ]
          : [
              'cb_are_leaking_89',
              'cb_are_loose_91',
              'cb_are_incomplete_94',
              'cb_are_blocked_52',
              'cb_are_rusted_18',
              'cb_do_not_have_sufficient_slope_65',
              'cb_other_4581'
            ];
      if (!defectKeys.any(isChecked)) {
        return 'Select at least one Defect option.';
      }

      final otherChecked = isChecked(isSoon ? 'cb_other_458' : 'cb_other_4581');
      final otherText =
          (state.answers[isSoon ? 'et_other_423' : 'et_other_4231'] ?? '')
              .trim();
      if (otherChecked && otherText.isEmpty) {
        return 'Enter Other defect text or uncheck Other.';
      }
    }
    if (_screenId == _rwgNotInspectedScreenId) {
      final checked =
          (state.answers['cb_not_inspected'] ?? '').trim().toLowerCase() ==
              'true';
      if (!checked) {
        return 'Select Not inspected.';
      }
    }
    return null;
  }

  /// Legacy parity helper for Environmental Impact screen reset.
  ///
  /// Clears all non-label field values on the current screen, clears edited
  /// phrases and user note, persists immediately, and marks screen incomplete.
  Future<bool> resetCurrentScreen() async {
    if (state.screenDefinition == null) return false;
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final cleared = <String, String>{};
      for (final field in state.screenDefinition!.fields) {
        if (field.type == InspectionFieldType.label) continue;
        cleared[field.id] = '';
      }

      await _repo.saveScreenAnswers(
        surveyId: _surveyId,
        screenId: _screenId,
        answers: cleared,
      );
      await _repo.savePhraseOutput(
        surveyId: _surveyId,
        screenId: _screenId,
        phraseJson: '[]',
      );
      await _repo.saveUserNote(
        surveyId: _surveyId,
        screenId: _screenId,
        note: '',
      );
      await _repo.setScreenCompleted(
        surveyId: _surveyId,
        screenId: _screenId,
        isCompleted: false,
      );

      // Keep sync payloads aligned with local reset state.
      state = state.copyWith(
        answers: cleared,
        userNote: '',
        clearEditedPhraseText: true,
      );
      await _queuePhraseOutputForSync();
      await _queueUserNoteForSync();
      await _queueAnswersForSync();

      _ref.read(inspectionRefreshProvider.notifier).state++;
      state = state.copyWith(isSaving: false, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to reset screen: $e',
      );
      return false;
    }
  }

  // ─── Phrase Persistence ──────────────────────────────────────────

  /// Persist phrase output — uses user-edited text when available,
  /// otherwise auto-generates from the phrase engine.
  Future<void> _persistPhraseOutput() async {
    if (state.screenDefinition == null) return;
    try {
      final List<String> phrases;
      if (state.editedPhraseText != null) {
        // User has manually edited the preview — persist their text.
        // Split by double-newline (paragraph breaks) to keep the
        // List<String> format that the export pipeline expects.
        phrases = state.editedPhraseText!
            .split('\n\n')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
      } else {
        // Auto-generate from phrase engine (original behaviour).
        final phraseEngine = _ref.read(inspectionPhraseEngineProvider);
        final enginePhrases =
            phraseEngine?.buildPhrases(_screenId, state.answers) ??
                const <String>[];
        final fieldPhrases = FieldPhraseProcessor.buildFieldPhrases(
            state.screenDefinition!.fields, state.answers);
        phrases = [...enginePhrases, ...fieldPhrases];
      }

      final phraseJson = jsonEncode(phrases);
      await _repo.savePhraseOutput(
        surveyId: _surveyId,
        screenId: _screenId,
        phraseJson: phraseJson,
      );

      // Queue aggregated section phrase output for sync.
      await _queuePhraseOutputForSync();
    } catch (e) {
      // Non-fatal: phrase persistence should not block screen save.
      debugPrint('[InspectionSync] Failed to persist phrase output: $e');
    }
  }

  /// Queue a section UPDATE with aggregated phraseOutput from all
  /// screens in this screen's section.
  ///
  /// CRITICAL: Payload includes full section metadata (surveyId, title,
  /// order, sectionTypeKey) so the upsert fallback in SyncManager can
  /// create the section if the server returns 404. V2 sections are virtual
  /// entities (deterministic UUIDs) that don't exist in the survey_sections
  /// table — without enriched payloads, the fallback has nothing to work with.
  Future<void> _queuePhraseOutputForSync() async {
    try {
      final syncManager = _ref.read(syncManagerProvider);
      final sectionKey =
          await _repo.getSectionKeyForScreen(_surveyId, _screenId);
      if (sectionKey == null) return;

      final sectionId = V2SyncHelper.sectionSyncId(_surveyId, sectionKey);
      final aggregatedJson =
          await _repo.getAggregatedPhraseOutput(_surveyId, sectionKey);
      final sectionMeta = await _getSectionMeta(sectionKey);

      await syncManager.queueSync(
        entityType: SyncEntityType.section,
        entityId: sectionId,
        action: SyncAction.update,
        payload: {
          'surveyId': _surveyId,
          'title': sectionMeta?.title ?? sectionKey,
          'order': sectionMeta?.order ?? 0,
          'sectionTypeKey': sectionKey,
          'phraseOutput': aggregatedJson,
        },
      );
    } catch (e) {
      debugPrint('[InspectionSync] Failed to queue phrase output: $e');
    }
  }

  // ─── User Note Persistence ──────────────────────────────────────

  /// Persist the surveyor's custom note for this screen and queue for sync.
  Future<void> _persistUserNote() async {
    try {
      await _repo.saveUserNote(
        surveyId: _surveyId,
        screenId: _screenId,
        note: state.userNote.trim(),
      );
      await _queueUserNoteForSync();
    } catch (e) {
      // Non-fatal: note persistence should not block screen save.
      debugPrint('[InspectionSync] Failed to persist user note: $e');
    }
  }

  /// Queue a section UPDATE with aggregated userNotes from all
  /// screens in this screen's section.
  ///
  /// CRITICAL: Payload includes full section metadata — see
  /// [_queuePhraseOutputForSync] for rationale.
  Future<void> _queueUserNoteForSync() async {
    try {
      final syncManager = _ref.read(syncManagerProvider);
      final sectionKey =
          await _repo.getSectionKeyForScreen(_surveyId, _screenId);
      if (sectionKey == null) return;

      final sectionId = V2SyncHelper.sectionSyncId(_surveyId, sectionKey);
      final aggregatedJson =
          await _repo.getAggregatedUserNotes(_surveyId, sectionKey);
      final sectionMeta = await _getSectionMeta(sectionKey);

      await syncManager.queueSync(
        entityType: SyncEntityType.section,
        entityId: sectionId,
        action: SyncAction.update,
        payload: {
          'surveyId': _surveyId,
          'title': sectionMeta?.title ?? sectionKey,
          'order': sectionMeta?.order ?? 0,
          'sectionTypeKey': sectionKey,
          'userNotes': aggregatedJson,
        },
      );
    } catch (e) {
      debugPrint('[InspectionSync] Failed to queue user notes: $e');
    }
  }

  // ─── Sync Helpers ────────────────────────────────────────────────

  /// Queue V2 section CREATE entries so the backend has parent Section
  /// records before any answers arrive (TIER 2 → TIER 3 dependency).
  Future<void> _queueV2SectionsForSync() async {
    try {
      final syncManager = _ref.read(syncManagerProvider);
      final sections = await _repo.getV2SectionMeta();

      for (final section in sections) {
        final sectionId = V2SyncHelper.sectionSyncId(_surveyId, section.key);
        await syncManager.queueSync(
          entityType: SyncEntityType.section,
          entityId: sectionId,
          action: SyncAction.create,
          payload: {
            'surveyId': _surveyId,
            'title': section.title,
            'order': section.order,
            'sectionTypeKey': section.key,
          },
        );
      }
      debugPrint(
          '[InspectionSync] Queued ${sections.length} V2 sections for survey $_surveyId');
    } catch (e) {
      // Non-fatal: local data is already saved, sync will be retried.
      debugPrint('[InspectionSync] Failed to queue sections: $e');
    }
  }

  /// Look up V2 section metadata (title, order) by sectionKey from the tree.
  Future<({String title, int order})?> _getSectionMeta(
      String sectionKey) async {
    try {
      final sections = await _repo.getV2SectionMeta();
      final match = sections.where((s) => s.key == sectionKey).firstOrNull;
      return match != null ? (title: match.title, order: match.order) : null;
    } catch (_) {
      return null;
    }
  }

  /// Queue answer sync entries for changed/new answers on this screen.
  Future<void> _queueAnswersForSync() async {
    try {
      final syncManager = _ref.read(syncManagerProvider);

      // Resolve sectionKey → deterministic section UUID for the FK.
      final sectionKey =
          await _repo.getSectionKeyForScreen(_surveyId, _screenId);
      if (sectionKey == null) return;
      final sectionId = V2SyncHelper.sectionSyncId(_surveyId, sectionKey);

      final currentAnswers = _syncAnswersForScreen(_screenId, state.answers);
      final initialAnswers = _syncAnswersForScreen(_screenId, _initialAnswers);

      for (final entry in currentAnswers.entries) {
        final fieldKey = entry.key;
        final value = entry.value;

        // Skip empty values — backend rejects with @IsNotEmpty().
        if (value.trim().isEmpty) continue;

        // Skip unchanged answers — no need to re-queue.
        if (initialAnswers[fieldKey] == value) continue;

        final isNew = !initialAnswers.containsKey(fieldKey);
        final answerId =
            V2SyncHelper.answerSyncId(_surveyId, _screenId, fieldKey);

        await syncManager.queueSync(
          entityType: SyncEntityType.answer,
          entityId: answerId,
          action: isNew ? SyncAction.create : SyncAction.update,
          payload: {
            'sectionId': sectionId,
            'surveyId': _surveyId,
            'questionKey': fieldKey,
            'value': value,
          },
        );
      }

      // Update initial answers so subsequent saves detect the right diff.
      _initialAnswers = Map<String, String>.from(state.answers);
    } catch (e) {
      // Non-fatal: local data is already saved, sync will be retried.
      debugPrint('[InspectionSync] Failed to queue answers: $e');
    }
  }

  Map<String, String> _syncAnswersForScreen(
    String screenId,
    Map<String, String> answers,
  ) {
    if (LegacyMainWallsSyncMapping.handlesScreen(screenId)) {
      return LegacyMainWallsSyncMapping.buildRemoteAnswers(screenId, answers) ??
          const <String, String>{};
    }

    return <String, String>{
      for (final entry in answers.entries)
        if (entry.value.trim().isNotEmpty) entry.key: entry.value,
    };
  }
}

final inspectionScreenProvider = StateNotifierProvider.autoDispose.family<
    InspectionScreenNotifier,
    InspectionScreenState,
    ({String surveyId, String screenId})>(
  (ref, params) {
    final repo = ref.watch(inspectionRepositoryProvider);
    return InspectionScreenNotifier(
        repo, ref, params.surveyId, params.screenId);
  },
);
