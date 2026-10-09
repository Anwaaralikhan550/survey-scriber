import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - outside screen id aliases', () {
    const phraseTexts = <String, String>{
      '{E_ROOF_COVERING_REPAIR}::{ROOF_FIT_FOR_PURPOSE}': 'roof-fit',
      '{E_ROOF_COVERING_REPAIR}::{END_OF_USEFUL_LIFE}': 'roof-eoul',
      '{E_RAINWATER_GOODS_ABOUT}::{RWG_BLOCKED}': 'rwg-blocked',
      '{E_RAINWATER_GOODS_ABOUT}::{RWG_BLOCKED_GULLIES}':
          'rwg-blocked-gullies',
      '{E_RAINWATER_GOODS_ABOUT}::{RWG_OPEN_RUNOFFS}': 'rwg-open-runoffs',
      '{E_RAINWATER_GOODS_ABOUT}::{RAINWATER_GOODS_SHARED}': 'rwg-shared',
      '{E_WINDOWS}::{WINDOWS_RANDOM_SAMPLING}': 'windows-random-sampling',
      '{E_WINDOWS}::{WINDOWS_IN_POOR_CONDITION}': 'windows-poor-condition',
    };

    const engine = InspectionPhraseEngine(phraseTexts);


  });
}
