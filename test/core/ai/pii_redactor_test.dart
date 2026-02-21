import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/core/ai/pii_redactor.dart';

void main() {
  late PiiRedactor redactor;

  setUp(() {
    redactor = PiiRedactor();
  });

  group('PiiRedactor', () {
    group('redactText', () {
      test('replaces email addresses with tokens', () {
        final result = redactor.redactText('Contact john@example.com for info');

        expect(result.redacted, contains('[EMAIL_0]'));
        expect(result.redacted, isNot(contains('john@example.com')));
        expect(result.mapping['[EMAIL_0]'], 'john@example.com');
      });

      test('replaces multiple emails with unique tokens', () {
        final result = redactor.redactText(
          'From: a@b.com To: c@d.com',
        );

        expect(result.redacted, contains('[EMAIL_0]'));
        expect(result.redacted, contains('[EMAIL_1]'));
        expect(result.mapping.length, 2);
      });

      test('replaces UK phone numbers', () {
        final result = redactor.redactText('Call 07700 900123 today');

        expect(result.redacted, contains('[PHONE_'));
        expect(result.redacted, isNot(contains('07700 900123')));
      });

      test('replaces UK postcodes', () {
        final result = redactor.redactText('Located at SW1A 1AA');

        expect(result.redacted, contains('[POSTCODE_'));
        expect(result.redacted, isNot(contains('SW1A 1AA')));
      });

      test('returns empty mapping when no PII found', () {
        final result = redactor.redactText('No personal info here');

        expect(result.redacted, 'No personal info here');
        expect(result.mapping, isEmpty);
      });

      test('handles empty string', () {
        final result = redactor.redactText('');
        expect(result.redacted, '');
        expect(result.mapping, isEmpty);
      });
    });

    group('redactAddress', () {
      test('replaces address with token', () {
        final result = redactor.redactAddress('42 Baker Street, London');

        expect(result.redacted, '[PROPERTY_ADDRESS]');
        expect(result.mapping['[PROPERTY_ADDRESS]'],
            '42 Baker Street, London');
      });

      test('handles empty address', () {
        final result = redactor.redactAddress('');
        expect(result.redacted, '');
        expect(result.mapping, isEmpty);
      });
    });

    group('redactName', () {
      test('replaces name with token', () {
        final result = redactor.redactName('John Smith');

        expect(result.redacted, '[CLIENT_NAME]');
        expect(result.mapping['[CLIENT_NAME]'], 'John Smith');
      });

      test('handles empty name', () {
        final result = redactor.redactName('');
        expect(result.redacted, '');
        expect(result.mapping, isEmpty);
      });
    });

    group('redactAnswerMap', () {
      test('redacts PII in answer values', () {
        final answers = {
          'email_field': 'test@example.com',
          'name_field': 'Regular text',
        };

        final result = redactor.redactAnswerMap(answers);

        expect(result.redacted['email_field'], contains('[EMAIL_'));
        expect(result.redacted['name_field'], 'Regular text');
      });

      test('preserves keys unchanged', () {
        final answers = {'field_1': 'value', 'field_2': 'test@x.com'};
        final result = redactor.redactAnswerMap(answers);

        expect(result.redacted.keys, containsAll(['field_1', 'field_2']));
      });
    });

    group('unredact', () {
      test('restores original text from mapping', () {
        final original = 'Contact john@example.com at SW1A 1AA';
        final redacted = redactor.redactText(original);
        final restored = redactor.unredact(redacted.redacted, redacted.mapping);

        expect(restored, original);
      });

      test('handles text with no tokens', () {
        final result = redactor.unredact('No tokens here', {});
        expect(result, 'No tokens here');
      });

      test('handles partial mapping (missing tokens left as-is)', () {
        final result = redactor.unredact(
          'Hello [EMAIL_0] and [EMAIL_1]',
          {'[EMAIL_0]': 'a@b.com'},
        );

        expect(result, contains('a@b.com'));
        expect(result, contains('[EMAIL_1]'));
      });
    });

    group('round-trip integrity', () {
      test('redact then unredact preserves original text', () {
        const original =
            'Survey for john@test.co.uk at SW1A 2PW';

        final redacted = redactor.redactText(original);
        final restored = redactor.unredact(redacted.redacted, redacted.mapping);

        expect(restored, original);
      });
    });
  });
}
