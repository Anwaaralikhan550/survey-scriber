import 'package:drift/drift.dart';

import '../../../core/database/base_survey_repository.dart';
import '../../../core/network/api_client.dart';

class InspectionRepository extends BaseSurveyRepository {
  InspectionRepository(super.db, {ApiClient? apiClient})
      : super(
          treeAsset: 'assets/property_inspection/inspection_tree.json',
          localOverrideName: 'inspection_v2_tree.json',
          apiClient: apiClient,
          treeType: 'inspection_v2',
          // Bump this when the bundled JSON is updated so stale OTA
          // caches are cleared and the new asset takes effect.
          bundledTreeVersion: 5,
        );

  /// Returns condition ratings grouped by section key.
  /// Each entry maps sectionKey -> list of rating values (e.g., "1", "2", "3").
  Future<Map<String, List<String>>> getConditionRatingsBySection(
    String surveyId,
  ) async {
    // Join answers with screens to get section key
    final query = db.select(db.inspectionV2Answers).join([
      innerJoin(
        db.inspectionV2Screens,
        db.inspectionV2Screens.screenId
                .equalsExp(db.inspectionV2Answers.screenId) &
            db.inspectionV2Screens.surveyId
                .equalsExp(db.inspectionV2Answers.surveyId),
      ),
    ])
      ..where(db.inspectionV2Answers.surveyId.equals(surveyId) &
          db.inspectionV2Answers.fieldKey
              .equals('android_material_design_spinner4') &
          db.inspectionV2Answers.value.isNotNull());

    final rows = await query.get();
    final result = <String, List<String>>{};
    for (final row in rows) {
      final sectionKey =
          row.readTable(db.inspectionV2Screens).sectionKey;
      final value = row.readTable(db.inspectionV2Answers).value;
      if (value != null && value.isNotEmpty) {
        result.putIfAbsent(sectionKey, () => []).add(value);
      }
    }
    return result;
  }
}
