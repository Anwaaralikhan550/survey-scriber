import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - roof repairs parity', () {
    const phraseTexts = <String, String>{
      '{E_RC_TILES}::{REPAIR_SOON}':
          'tiles-soon {RC_ROOF_REPAIR_TILES_ONE_OR_FEW} {RC_ROOF_REPAIR_TILES_ISSUE}',
      '{E_RC_TILES}::{REPAIR_NOW}':
          'tiles-now {RC_ROOF_REPAIR_TILES_ONE_OR_FEW} {RC_ROOF_REPAIR_TILES_ISSUE}',
      '{E_RC_FLAT_ROOF_REPAIR}::{REPAIR_SOON}':
          'flat-soon {RC_FLAT_ROOF_REPAIR_COVERED}',
      '{E_RC_FLAT_ROOF_REPAIR}::{REPAIR_NOW}':
          'flat-now {RC_FLAT_ROOF_REPAIR_COVERED}',
      '{E_RC_PARAPET_WALL_REPAIR}::{REPAIR_SOON}':
          'parapet-soon {RC_PARAPET_WALL_REPAIR_SUBJECT} {RC_PARAPET_WALL_REPAIR_LOCATION} {RC_PARAPET_WALL_REPAIR_ISSUE}',
      '{E_RC_PARAPET_WALL_REPAIR}::{REPAIR_NOW}':
          'parapet-now {RC_PARAPET_WALL_REPAIR_SUBJECT} {RC_PARAPET_WALL_REPAIR_LOCATION} {RC_PARAPET_WALL_REPAIR_ISSUE}',
      '{E_RC_VERGE_REPAIR}::{REPAIR_SOON}':
          'verge-soon {RC_VERGE_REPAIR_ITEM} {RC_VERGE_REPAIR_ISSUE}',
      '{E_RC_VERGE_REPAIR}::{REPAIR_NOW}':
          'verge-now {RC_VERGE_REPAIR_ITEM} {RC_VERGE_REPAIR_ISSUE}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('repair tiles accepts legacy condition id', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_roof_repair_tiles',
        {
          'llMainContainer': 'Repair soon',
          'cb_roof_14': 'true',
          'cb_are_loose_71': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('tiles-soon'));
    });

    test('flat roof repair accepts legacy condition id', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_roof_repair_flat_roof',
        {
          'llMainContainer': 'Repair soon',
          'cb_torn': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('flat-soon'));
    });

    test('parapet wall repair accepts legacy condition id', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_roof_repair_parapet_wall',
        {
          'llMainContainer': 'Repair soon',
          'cb_rendering_68': 'true',
          'cb_right_72': 'true',
          'cb_damaged_94': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('parapet-soon'));
    });

    test('verge repair accepts legacy condition id', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_roof_repair_verge',
        {
          'llMainContainer': 'Repair soon',
          'cb_mortar_58': 'true',
          'cb_damaged_32': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('verge-soon'));
    });
  });
}
