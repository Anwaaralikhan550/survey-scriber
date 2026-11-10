import '../../../core/database/base_survey_repository.dart';
import '../../../core/survey_tree/tree_sync.dart';

class ValuationRepository extends BaseSurveyRepository {
  ValuationRepository(super.db, {TreeSync? treeSync})
      : super(
          treeAsset: 'assets/property_valuation/valuation_tree.json',
          idPrefix: 'val_',
          treeSync: treeSync,
          treeType: 'valuation_v2',
          bundledTreeVersion: bundledVersion,
        );

  /// Bump this when the bundled JSON changes (see InspectionRepository).
  static const int bundledVersion = 4;
}
