import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - chimney stack-type parity', () {
    const phraseTexts = <String, String>{
      '{E_CHIMNEY_SINGLE_STACK}::{STACK}': 'single-stack',
      '{E_CHIMNEY_MULTI_STACK}::{STACK}': 'multi-stack {CS_STACK_MULTIPLE_NUMBER}',
      '{E_CHIMNEY_SINGLE_STACK}::{STACK_POTS}': 'single-pots {CS_POTS}',
      '{E_CHIMNEY_MULTI_STACK}::{STACK_POTS}': 'multi-pots several pots',
      '{E_CHIMNEY_SINGLE_STACK}::{STACK_LOCATION}':
          'single-location {CS_LOCATION}',
      '{E_CHIMNEY_MULTI_STACK}::{STACK_LOCATION}':
          'multi-location {CS_LOCATION}',
      '{E_CHIMNEY_SINGLE_STACK}::{SHARED_CHIMNEY}':
          'single-shared {CS_SHARED_CHIMNEY} {IS_ARE}',
      '{E_CHIMNEY_MULTI_STACK}::{SHARED_CHIMNEY}':
          'multi-shared {CS_SHARED_CHIMNEY} {IS_ARE}',
      '{E_CHIMNEY_SINGLE_STACK}::{LEANING_CHIMNEY}':
          'single-leaning {CS_LEANING_CHIMNEY} {IS_ARE}',
      '{E_CHIMNEY_MULTI_STACK}::{LEANING_CHIMNEY}':
          'multi-leaning {CS_LEANING_CHIMNEY} {IS_ARE}',
      '{E_CHIMNEY_SINGLE_STACK}::{LEANING_CHIMNEY_CONDITION_OK}': 'single-ok',
      '{E_CHIMNEY_MULTI_STACK}::{LEANING_CHIMNEY_CONDITION_OK}': 'multi-ok',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('location uses multi template when stack type is Multiple', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_location',
        {
          'android_material_design_spinner3': 'Multiple',
          'ch1': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('multi-location'));
    });

    test('multiple stacks still emit pots phrase without pots input', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_stacks',
        {
          'android_material_design_spinner3': 'Multiple',
          'EtMultipleNumber': 'two',
        },
      );

      expect(phrases, isNotEmpty);
      expect(
        phrases.map((p) => p.toLowerCase()).join(' '),
        contains('multi-pots several pots'),
      );
    });

    test('single stack does not emit pots phrase when pots input is empty', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_stacks',
        {
          'android_material_design_spinner3': 'Single',
        },
      );

      expect(
        phrases.map((p) => p.toLowerCase()).join(' '),
        isNot(contains('single-pots')),
      );
    });

    test('location uses single template when stack type is Single', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_location',
        {
          'android_material_design_spinner3': 'Single',
          'ch1': 'true',
          'ch2': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('single-location'));
    });

    test('legacy stack type key also routes location phrase code', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_location',
        {
          'android_material_design_spinner': 'Single',
          'ch1': 'true',
          'ch2': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('single-location'));
    });

    test('shared chimney uses stack type instead of selected count', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_shared_chimney',
        {
          'android_material_design_spinner3': 'Multiple',
          'ch1': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('multi-shared'));
    });

    test('leaning chimney uses stack type for both base and condition text', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_leaning_chimney',
        {
          'android_material_design_spinner3': 'Single',
          'ch1': 'true',
          'ch2': 'true',
          'android_material_design_spinner4': 'OK',
        },
      );

      expect(phrases, hasLength(2));
      expect(phrases.first.toLowerCase(), contains('single-leaning'));
      expect(phrases.last.toLowerCase(), contains('single-ok'));
    });

    test('legacy stack type key also routes stacks phrase code', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_stacks',
        {
          'android_material_design_spinner': 'Multiple',
          'EtMultipleNumber': 'three',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('multi-stack'));
      expect(
        phrases.map((p) => p.toLowerCase()).join(' '),
        contains('multi-pots several pots'),
      );
    });
  });
}
