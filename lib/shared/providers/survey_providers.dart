import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mock_survey_repository.dart';

final surveyRepositoryProvider = Provider<SurveyRepository>((ref) => MockSurveyRepository());
