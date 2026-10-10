import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_export/data/services/paragraph_composer.dart';

void main() {
  final texts = (jsonDecode(File('assets/property_inspection/phrase_texts.json')
      .readAsStringSync()) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v?.toString() ?? ''));
  test('debug composer match2', () {
    final composer = ParagraphComposer(texts);
    final out = composer.compose([
      'There is a porch to the front of the property, and this is built of brick walls and timber double glazed sections.',
      'The roof over the porch is pitched and covered in concrete tiles.',
      'The porch incorporates double glazed pvc door(s).',
      'Also, the porch incorporates double glazed pvc windows(s).',
      'The floors are covered in tiles and laminate flooring.',
    ]);
    print('OUTPUT COUNT: ${out.length}');
    for (final o in out) print('>>> $o');
  });
}
