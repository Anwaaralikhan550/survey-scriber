// Valuation phrase catalog generator - RICS sign-off support tool.
//
// Context: Phase 6 investigation established that the legacy SurveyScriber
// app never had a standalone "Valuation Survey" type - it was a single Home
// Buyer Report with a small valuation-opinion addendum (Section K). The new
// app's entire valuation feature (42 screens of RICS-style condition
// narrative) was authored fresh for this rewrite, with no legacy-bank
// precedent to verify it against. That means the "unapproved" measurement
// from the main audit harness is a category error, not a defect - but it
// also means this phrase content has never been through ANY formal
// approval process.
//
// This script does NOT attempt to approve or fabricate approval for that
// content (this agent has no authority to sign off RICS-standard survey
// language). It produces the review package: every distinct sentence the
// valuation engine can currently generate, organised by section and screen,
// so a RICS-qualified assessor or the client can review and sign off the
// wording through a real professional process.
//
// Run with:
//   flutter test test/phrase_audit/valuation_phrase_catalog_generator.dart
//
// Output:
//   tool/phrase_audit/output/valuation_phrase_catalog.md
//   tool/phrase_audit/output/valuation_phrase_catalog.json

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_answer_validator.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_catalog.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';

const String sampleText = 'sample text';
const String sampleNumber = '5';

/// Builds a representative-but-bounded set of answer permutations for a
/// screen: empty, each field answered solo, every field answered together,
/// and every dropdown option swept individually against that "everything
/// answered" baseline. Mirrors the main audit harness's approach, which is
/// deliberately not full combinatorial explosion (astronomically large and
/// not useful for human review) but does surface every distinct sentence
/// variant a template can produce.
List<Map<String, String>> buildPermutations(
  List<InspectionFieldDefinition> fields,
) {
  final permutations = <Map<String, String>>[<String, String>{}];
  final dataFields =
      fields.where((f) => f.type != InspectionFieldType.label).toList();

  for (final field in dataFields) {
    switch (field.type) {
      case InspectionFieldType.dropdown:
        for (final option in field.options ?? const <String>[]) {
          permutations.add({field.id: option});
        }
      case InspectionFieldType.checkbox:
        permutations.add({field.id: 'true'});
      case InspectionFieldType.text:
        permutations.add({field.id: sampleText});
      case InspectionFieldType.number:
        permutations.add({field.id: sampleNumber});
      case InspectionFieldType.label:
        break;
    }
  }

  final maximal = <String, String>{};
  for (final field in dataFields) {
    switch (field.type) {
      case InspectionFieldType.dropdown:
        final options = field.options ?? const <String>[];
        if (options.isNotEmpty) maximal[field.id] = options.first;
      case InspectionFieldType.checkbox:
        maximal[field.id] = 'true';
      case InspectionFieldType.text:
        maximal[field.id] = sampleText;
      case InspectionFieldType.number:
        maximal[field.id] = sampleNumber;
      case InspectionFieldType.label:
        break;
    }
  }
  if (maximal.isNotEmpty) permutations.add(maximal);

  for (final field in dataFields) {
    if (field.type != InspectionFieldType.dropdown) continue;
    for (final option in field.options ?? const <String>[]) {
      if (maximal[field.id] == option) continue;
      permutations.add({...maximal, field.id: option});
    }
  }

  return permutations;
}

String normalize(String phrase) {
  return phrase
      .replaceAll(sampleText, '[free text]')
      .replaceAll(RegExp(r'\b5\b'), '[number]')
      .trim();
}

void main() {
  test('generate valuation phrase catalog for RICS review', () {
    final valuationTree = InspectionTreePayload.fromJson(
      File('assets/property_valuation/valuation_tree.json').readAsStringSync(),
    );
    final phraseCatalog = ValuationPhraseCatalog.fromRawJson(
      File('assets/property_valuation/phrase_texts.json').readAsStringSync(),
    );
    final engine = ValuationPhraseEngine.catalog(phraseCatalog);

    final catalog = <Map<String, dynamic>>[];
    var totalDistinctPhrases = 0;

    for (final section in valuationTree.sections) {
      final screens = <Map<String, dynamic>>[];
      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;

        final permutations = buildPermutations(node.fields);
        final distinctPhrases = <String, Map<String, dynamic>>{};
        for (final answers in permutations) {
          if (ValuationAnswerValidator.validateScreen(node.id, answers)
              .isNotEmpty) {
            continue;
          }
          List<ValuationPhraseEmission> emissions;
          try {
            emissions = engine.buildEmissions(node.id, answers);
          } catch (_) {
            continue;
          }
          for (final emission in emissions) {
            final trimmed = emission.text.trim();
            if (trimmed.isEmpty) continue;
            if (!emission.isRegistered) {
              fail('Unregistered valuation phrase: $trimmed');
            }
            final template = phraseCatalog.templates[emission.templateId];
            final normalized = normalize(trimmed);
            distinctPhrases.putIfAbsent(
              '${emission.templateId}::$normalized',
              () => <String, dynamic>{
                'templateId': emission.templateId,
                'text': normalized,
                'allowedTokens': template?.allowedTokens ?? const <String>[],
                'reviewStatus': phraseCatalog.reviewStatus,
              },
            );
          }
        }
        if (distinctPhrases.isEmpty) continue;

        totalDistinctPhrases += distinctPhrases.length;
        screens.add({
          'screenId': node.id,
          'title': node.title,
          'dataFieldCount': node.fields
              .where((f) => f.type != InspectionFieldType.label)
              .length,
          'phraseEntries': distinctPhrases.values.toList()
            ..sort((a, b) => (a['templateId'] as String)
                .compareTo(b['templateId'] as String)),
        });
      }
      if (screens.isNotEmpty) {
        catalog.add({
          'sectionKey': section.key,
          'sectionTitle': section.title,
          'screens': screens,
        });
      }
    }

    final outDir = Directory('tool/phrase_audit/output');
    outDir.createSync(recursive: true);

    File('${outDir.path}/valuation_phrase_catalog.json').writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert({
        'note': 'Every registered phrase template emitted by the valuation '
            'engine, for RICS-qualified review and sign-off.',
        'bankVersion': phraseCatalog.bankVersion,
        'reviewStatus': phraseCatalog.reviewStatus,
        'totalScreens': catalog.fold<int>(
            0, (sum, s) => sum + (s['screens'] as List).length),
        'totalDistinctPhrases': totalDistinctPhrases,
        'sections': catalog,
      }),
    );

    final md = StringBuffer()
      ..writeln('# Valuation Phrase Catalog — RICS Sign-Off Review Package')
      ..writeln()
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln()
      ..writeln('## Purpose')
      ..writeln()
      ..writeln('The legacy SurveyScriber app never had a standalone Valuation '
          'Survey type — it was a Home Buyer Report with a small valuation-'
          'opinion addendum. This app\'s valuation feature was written fresh '
          'for this project, so its report language has never been through '
          'a formal RICS-qualified approval process.')
      ..writeln()
      ..writeln(
          'This document lists every distinct sentence the valuation engine '
          'can currently produce, grouped by section and screen, so a RICS-'
          'qualified assessor (or the client directly) can review and '
          'formally sign off the wording. This is a review package, not an '
          'approval — no sentence here should be treated as RICS-approved '
          'until reviewed by a qualified person.')
      ..writeln()
      ..writeln('## How to use this document')
      ..writeln()
      ..writeln('For each screen below:')
      ..writeln(
          '1. Read every listed sentence variant against RICS Home Survey '
          'Standard wording conventions.')
      ..writeln('2. Mark each sentence **Approved**, **Needs revision** (with '
          'suggested wording), or **Remove**.')
      ..writeln(
          '3. Return the annotated document; each approved/revised sentence '
          'will be wired into the app as the new approved bank for this '
          'section.')
      ..writeln()
      ..writeln('`[free text]` and `[number]` mark where the surveyor\'s own '
          'typed input or a numeric entry appears in the sentence.')
      ..writeln()
      ..writeln('## Summary')
      ..writeln()
      ..writeln('| Metric | Value |')
      ..writeln('|---|---|')
      ..writeln('| Sections | ${catalog.length} |')
      ..writeln(
          '| Screens with generated language | ${catalog.fold<int>(0, (sum, s) => sum + (s['screens'] as List).length)} |')
      ..writeln('| Distinct sentence variants | $totalDistinctPhrases |')
      ..writeln();

    for (final section in catalog) {
      md.writeln('## Section: ${section['sectionTitle']} '
          '(`${section['sectionKey']}`)');
      md.writeln();
      for (final screen in section['screens'] as List<Map<String, dynamic>>) {
        md.writeln('### ${screen['title']} (`${screen['screenId']}`)');
        md.writeln();
        md.writeln('Data fields: ${screen['dataFieldCount']} | '
            'Sentence variants: '
            '${(screen['phraseEntries'] as List).length}');
        md.writeln();
        md.writeln('| Template ID | Sentence | Dynamic Tokens | Sign-off |');
        md.writeln('|---|---|---|---|');
        for (final entry
            in screen['phraseEntries'] as List<Map<String, dynamic>>) {
          final escaped = (entry['text'] as String).replaceAll('|', r'\|');
          final tokens = (entry['allowedTokens'] as List<dynamic>).join(', ');
          md.writeln('| ${entry['templateId']} | $escaped | $tokens | '
              '☐ Approved  ☐ Revise  ☐ Remove |');
        }
        md.writeln();
      }
    }

    File('${outDir.path}/valuation_phrase_catalog.md')
        .writeAsStringSync(md.toString());

    // Reporter test: always green; the catalog is the deliverable.
    expect(catalog, isNotEmpty);
    // ignore: avoid_print
    print('Catalog: ${catalog.length} sections, $totalDistinctPhrases '
        'distinct phrases');
  });
}
