import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - H3 Outside Areas (gardens) parity', () {
    const phraseTexts = <String, String>{
      '{H_OTHER}::{OTHER_GROUNDS}': 'grounds={OTH_GND_TYPE}',
      '{H_OTHER}::{H_OTHER_GARDENS}':
          '{GARDEN_TYPE} {FENCING}<br />\r\n<br />\r\n{POND}<br />\r\n<br />\r\n{BRICK_SHED}<br />\r\n<br />\r\n{TIMBER_SHED}',
      '{H_OTHER_GARDENS}::{GARDEN_TYPE}':
          'garden-type=name:{GRADEN_NAME}/type:{OTH_TYPE}',
      '{H_OTHER_GARDENS}::{COMMUNAL_GARDEN_TYPE}':
          'communal-garden-type={OTH_TYPE}',
      '{H_OTHER_GARDENS}::{FENCING_AVAILABLE}':
          'fencing=name:{GRADEN_NAME}/fences:{OTH_FENCES}/{FENCING_CONDITION}',
      '{H_OTHER_GARDENS}::{FENCING_NOT_AVAILABLE}':
          'no-fencing=name:{GRADEN_NAME}',
      '{H_OTHER_GARDENS}::{FENCING_CONDITION}':
          'fencing-condition={OTH_FENCES_CON}',
      '{H_OTHER_GARDENS}::{POND}': 'pond=name:{GRADEN_NAME}/cond:{OTH_POND_CON}',
      '{H_OTHER_GARDENS}::{BRICK_SHED}':
          'brick-shed=name:{GRADEN_NAME}/roof:{OTH_BRICK_ROOF_TYPE}/cover:{OTH_BRICK_ROOF_COVER}/cond:{OTH_BRICK_SHED_CON}',
      '{H_OTHER_GARDENS}::{TIMBER_SHED}':
          'timber-shed=name:{GRADEN_NAME}/roof:{OTH_TIMBER_ROOF_TYPE}/cover:{OTH_TIMBER_ROOF_COVER}/cond:{OTH_TIMBER_SHED_CON}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('grounds topography resolves the type', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_grounds',
        {'actv_type': 'Relatively level'},
      );
      expect(phrases.single.toLowerCase(),
          contains('grounds=relatively level'));
    });

    test('grounds topography with nothing answered emits nothing', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_grounds',
        const <String, String>{},
      );
      expect(phrases, isEmpty);
    });

    test('front garden resolves garden type', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_front_garden',
        {'cb_paved': 'true', 'cb_lawned': 'true'},
      );
      expect(phrases.join(' ').toLowerCase(),
          contains('garden-type=name:front/type:paved and lawned'));
    });

    test('rear garden resolves garden type with the correct garden name', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_front_garden__rear_garden',
        {'cb_decked': 'true'},
      );
      expect(phrases.join(' ').toLowerCase(),
          contains('garden-type=name:rear/type:decked'));
    });

    test('side and other gardens resolve with the correct garden names', () {
      final side = engine.buildPhrases(
        'activity_grounds_other_front_garden__side_garden',
        {'cb_lawned': 'true'},
      );
      expect(side.join(' ').toLowerCase(), contains('name:side/type:lawned'));

      final other = engine.buildPhrases(
        'activity_grounds_other_front_garden__other_garden',
        {'cb_lawned': 'true'},
      );
      expect(
          other.join(' ').toLowerCase(), contains('name:other/type:lawned'));
    });

    test('communal garden resolves via the dedicated communal template', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_front_garden__communal_garden',
        {'cb_lawned': 'true'},
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('communal-garden-type=lawned'));
      expect(all, isNot(contains(' garden-type=')));
    });

    test('no boundary fencing checkbox short-circuits the fencing branch', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_front_garden',
        {
          'ch20': 'true',
          'cb_fence_formed_in_timber': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('no-fencing=name:front'));
      expect(all, isNot(contains(' fencing=name:')));
    });

    test('fencing available resolves fences and condition', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_front_garden',
        {
          'cb_fence_formed_in_timber': 'true',
          'cb_fence_formed_in_hedges': 'true',
          'actv_fencing_condition': 'Reasonable',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('fencing=name:front/fences:timber and hedges'));
      expect(all, contains('fencing-condition=reasonable'));
    });

    test('pond resolves the correct garden condition, not a hardcoded value',
        () {
      final reasonable = engine.buildPhrases(
        'activity_grounds_other_front_garden',
        {'cb_pond': 'true', 'actv_pond_condition': 'Reasonable'},
      );
      expect(reasonable.join(' ').toLowerCase(),
          contains('pond=name:front/cond:reasonable'));

      final poor = engine.buildPhrases(
        'activity_grounds_other_front_garden',
        {'cb_pond': 'true', 'actv_pond_condition': 'Unsatisfactory and Poor'},
      );
      final poorAll = poor.join(' ').toLowerCase();
      expect(poorAll, contains('pond=name:front/cond:unsatisfactory and poor'));
      expect(poorAll, isNot(contains('cond:reasonable')));
    });

    test('pond without a condition answered emits nothing', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_front_garden',
        {'cb_pond': 'true'},
      );
      expect(phrases, isEmpty);
    });

    test('brick shed and timber shed resolve independently', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_front_garden',
        {
          'cb_brick_sheds': 'true',
          'actv_roof_type_brick': 'Pitched',
          'actv_roof_covered_in_brick': 'Tiles',
          'actv_brick_sheds_condition': 'Reasonable',
          'cb_timber_sheds': 'true',
          'actv_roof_type_timber': 'Flat',
          'actv_roof_covered_in_timber': 'Mineral felt',
          'actv_timber_sheds_condition': 'Satisfactory',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all,
          contains('brick-shed=name:front/roof:pitched/cover:tiles/cond:reasonable'));
      expect(
        all,
        contains(
            'timber-shed=name:front/roof:flat/cover:mineral felt/cond:satisfactory'),
      );
    });

    test('garden screen with nothing answered emits nothing', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_front_garden',
        const <String, String>{},
      );
      expect(phrases, isEmpty);
    });
  });
}
