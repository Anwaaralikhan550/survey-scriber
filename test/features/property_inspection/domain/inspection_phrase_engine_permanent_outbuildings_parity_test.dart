import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - H2 Permanent Outbuildings parity', () {
    const phraseTexts = <String, String>{
      '{H_OTHER}::{CONDITION_RATING}': 'condition={OTH_COND_RATING}',
      '{H_OTHER}::{NOTES}': 'notes={OTH_NOTES_H}',
      '{H_OTHER}::{NOT_INSPECTED}': 'not-inspected',
      '{H_OTHER}::{LARGE_OUTBUILDING}':
          'outbuilding-desc {LOB_CONST} {LOB_BUIL_TYPE} loc:{LOB_ROOF_LOC} '
              'underneath a {LOB_ROOF_TYPE} roof covered in {LOB_ROOF_COVER}. '
              'This appears in {LOB_CONDITION} condition. No repair is '
              'currently needed. The property must be maintained in the '
              'normal way.',
      '{H_OTHER}::{REPAIR_SHED}':
          'repair-shed=type:{OTH_REP_SHED_TYPE}/defect:{OTH_REP_SHED_DEF}',
      '{H_OTHER}::{REPAIR_OUTBUILDING}':
          'repair-outbuilding=type:{OTH_REP_OUTBUIL_TYPE}/defect:{OTH_REP_OUTBUIL_DEF}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('main screen resolves condition rating and notes', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_main_screen',
        {
          'android_material_design_spinner4': '2',
          'ar_etNote': 'shed roof re-felted last year',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('condition=2'));
      expect(all, contains('notes=shed roof re-felted last year'));
    });

    test('large outbuilding requires location and type before emitting', () {
      final missing = engine.buildPhrases(
        'activity_grounds_other_large_outbuildings',
        {'cb_brick': 'true'},
      );
      expect(missing, isEmpty);
    });

    test('large outbuilding resolves construction, type, location, roof and condition',
        () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_large_outbuildings',
        {
          'cb_brick': 'true',
          'cb_shed': 'true',
          'cb_rear': 'true',
          'cb_pitched': 'true',
          'cb_tiles': 'true',
          'actv_condition': 'Reasonable',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('brick'));
      expect(all, contains('shed'));
      expect(all, contains('loc:rear'));
      expect(all, contains('underneath a pitched roof covered in tiles'));
      expect(all, contains('this appears in reasonable condition'));
    });

    test('large outbuilding still emits with construction/roof/condition all empty',
        () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_large_outbuildings',
        {'cb_shed': 'true', 'cb_rear': 'true'},
      );
      expect(phrases, isNotEmpty);
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('shed'));
      expect(all, contains('loc:rear'));
      expect(all, isNot(contains('underneath')));
      expect(all, isNot(contains('this appears in')));
      expect(all, isNot(contains('{')));
    });

    test('shed repair resolves type and defect', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_repair_shed',
        {'cb_timber': 'true', 'cb_is_damaged': 'true'},
      );
      expect(phrases.single.toLowerCase(),
          contains('repair-shed=type:timber/defect:is damaged'));
    });

    test('outbuilding repair resolves type and defect', () {
      final phrases = engine.buildPhrases(
        'activity_other_repair_outbuilding',
        {'cb_workshop': 'true', 'cb_broken': 'true'},
      );
      expect(
        phrases.single.toLowerCase(),
        contains('repair-outbuilding=type:workshop/defect:broken'),
      );
    });

    test('not inspected is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_grounds_other_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first, 'not-inspected');

      final unchecked = engine.buildPhrases(
        'activity_grounds_other_not_inspected',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });
  });
}
