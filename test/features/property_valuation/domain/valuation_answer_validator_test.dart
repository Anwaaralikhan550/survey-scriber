import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_answer_validator.dart';

void main() {
  group('ValuationAnswerValidator', () {
    test('blocks no-parking alongside a positive parking selection', () {
      final errors = ValuationAnswerValidator.validateScreen(
        'accommodation_summary',
        const {
          'cb_none': 'true',
          'cb_garage': 'true',
        },
      );

      expect(errors, isNotEmpty);
    });

    test('blocks more than one mutually exclusive road type', () {
      final errors = ValuationAnswerValidator.validateScreen(
        'road',
        const {
          'cb_adopted': 'true',
          'cb_private': 'true',
        },
      );

      expect(errors.single, contains('one road type'));
    });

    test('requires a detail when Other parking is selected', () {
      final errors = ValuationAnswerValidator.validateScreen(
        'accommodation_summary',
        const {'cb_other_720': 'true'},
      );

      expect(errors.single, contains('description'));
    });

    test('requires a name when an other-room count is entered', () {
      final errors = ValuationAnswerValidator.validateScreen(
        'no_of_rooms',
        const {'et_other': '1'},
      );

      expect(errors.single, contains('Name the Other Room'));
    });

    test('accepts a valid year built and one parking type', () {
      final errors = ValuationAnswerValidator.validateScreen(
        'general_details',
        const {'et_age': '1986'},
      );

      expect(errors, isEmpty);
    });

    test('rejects an invalid year built before report completion', () {
      final errors = ValuationAnswerValidator.validateScreen(
        'general_details',
        const {'et_age': '5'},
      );

      expect(errors.single, contains('four-digit year'));
    });
  });
}
