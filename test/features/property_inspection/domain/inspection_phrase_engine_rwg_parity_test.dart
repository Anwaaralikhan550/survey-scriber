import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - RWG parity', () {
    const phraseTexts = <String, String>{
      '{E_RAINWATER_GOODS_ABOUT}::{RWG_CONDITION_RATING}':
          'rating={RWG_CONDITION_RATING}',
      '{E_RAINWATER_GOODS_ABOUT}::{RWG_NOTES}': 'notes={RWG_NOTES}',
      '{E_RAINWATER_GOODS_ABOUT}::{RAINWATER_GOODS_SHARED}': 'shared',
      '{E_RAINWATER_GOODS_ABOUT}::{RWG_ABOUT_TYPE}':
          'made_up={RWG_MADE_UP};type={RWG_TYPE}',
      '{E_RAINWATER_GOODS_ABOUT}::{RWG_ABOUT_CONDITION}':
          'condition={RWG_CONDITION}',
      '{E_RAINWATER_GOODS_ABOUT}::{RWG_STANDARD_TEXT}': 'standard',
      '{E_RAINWATER_GOODS_ABOUT}::{RWG_REPAIR_SOON}':
          '{RWG_REPAIR_ITEM_SOON}|{IS_ARE}|{RWG_REPAIR_DEFECT_SOON}',
      '{E_RAINWATER_GOODS_ABOUT}::{RWG_IF_TYPE_IF_INSUFFICIENT_SLOPE}':
          'slope-extra',
      '{E_RAINWATER_GOODS_WEATHER_CONDITION}::{WEATHER_CONDITION_WET}':
          'weather-wet',
      '{E_RAINWATER_GOODS_WEATHER_CONDITION}::{WEATHER_CONDITION_DRY}':
          'weather-dry',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('main screen supports both shared checkbox ids', () {
      final current = engine.buildPhrases(
        'activity_outside_property_rainwater_goods_main_screen',
        <String, String>{
          'cb_shared_rwg': 'true',
        },
      );
      expect(current.join(' ').toLowerCase(), contains('shared'));

      final legacy = engine.buildPhrases(
        'activity_outside_property_rainwater_goods_main_screen',
        <String, String>{
          'cb_Shared_RWG': 'true',
        },
      );
      expect(legacy.join(' ').toLowerCase(), contains('shared'));
    });

    test('about screen does not emit type phrase when made-up is empty', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_rwg_about',
        <String, String>{
          'cb_plastic': 'true',
          'actv_condition': 'reasonable',
        },
      );

      expect(phrases.join(' ').toLowerCase(), isNot(contains('made_up=')));
      expect(phrases.join(' ').toLowerCase(), contains('condition=reasonable'));
      expect(phrases.join(' ').toLowerCase(), contains('standard'));
    });

    test('repair soon injects typed other defect and slope extra phrase', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_rwg__repair_pipes_gutters',
        <String, String>{
          'actv_condition': 'Repair soon',
          'cb_pipes_101': 'true',
          'cb_other_458': 'true',
          'et_other_423': 'split joint',
          'cb_do_not_have_sufficient_slope_53': 'true',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('pipes'));
      expect(all, contains('split joint'));
      expect(all, contains('slope-extra'));
    });

    test('about screen accepts legacy llMainContainer for made-up dropdown', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_rwg_about',
        <String, String>{
          'llMainContainer': 'metal',
          'cb_metal': 'true',
          'actv_condition': 'good',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('made_up=metal'));
      expect(all, contains('type=metal'));
    });

    test('repair screen accepts legacy llMainContainer for condition dropdown',
        () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_rwg__repair_pipes_gutters',
        <String, String>{
          'llMainContainer': 'Repair soon',
          'cb_pipes_101': 'true',
          'cb_are_loose_39': 'true',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('pipes'));
      expect(all, contains('loose'));
    });

    test('weather screen accepts legacy llMainContainer for weather dropdown',
        () {
      final phrases = engine.buildPhrases(
        'activity_rwg_weather_condition',
        <String, String>{
          'llMainContainer': 'Wet',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('weather-wet'));
    });
  });
}
