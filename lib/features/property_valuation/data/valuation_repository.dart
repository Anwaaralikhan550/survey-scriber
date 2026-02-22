import '../../../core/database/base_survey_repository.dart';
import '../../../core/network/api_client.dart';

class ValuationRepository extends BaseSurveyRepository {
  ValuationRepository(super.db, {ApiClient? apiClient})
      : super(
          treeAsset: 'assets/property_valuation/valuation_tree.json',
          localOverrideName: 'valuation_v2_tree.json',
          idPrefix: 'val_',
          apiClient: apiClient,
          treeType: 'valuation_v2',
          bundledTreeVersion: 2,
        );
}
