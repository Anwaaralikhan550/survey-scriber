import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/core/phrases/phrase_bank_fill.dart';

void main() {
  test('published text wins, missing keys come from the bundled bank', () {
    final out = fillMissingPhrases(
      {'a': 'live A', 'b': 'live B'},
      {'a': 'app A', 'c': 'app C'},
    );
    expect(out, {'a': 'live A', 'b': 'live B', 'c': 'app C'});
  });

  test('valuation bank keeps its sentences under templates', () {
    final out = fillMissingPhrases(
      {'version': 3, 'templates': {'x': 'live'}},
      {'templates': {'x': 'app', 'y': 'app Y'}},
    );
    expect(out['version'], 3);
    expect(out['templates'], {'x': 'live', 'y': 'app Y'});
  });

  test('raw form fills too, and unreadable input is returned unchanged', () {
    final raw = fillMissingPhrasesRaw('{"a":"1"}', '{"a":"2","b":"3"}');
    expect(jsonDecode(raw), {'a': '1', 'b': '3'});
    expect(fillMissingPhrasesRaw('not json', '{"b":"3"}'), 'not json');
    expect(fillMissingPhrasesRaw('{"a":"1"}', '[1]'), '{"a":"1"}');
  });
}
