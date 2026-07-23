// Phrase permutation audit harness.
//
// Enumerates every screen in the inspection and valuation trees, drives the
// phrase engines through systematic answer permutations, and classifies the
// output against the approved legacy phrase bank
// (tool/phrase_audit/reference/old_phrase_bank.json).
//
// Findings per screen:
//   GAP              - screen has data fields but no permutation produced any
//                      phrase (client complaint: "phrases not generated").
//   PLACEHOLDER_LEAK - emitted text still contains an unresolved {TOKEN}.
//   GRAMMAR          - emitted text matches a known grammar-smell pattern.
//   UNAPPROVED       - emitted text matches neither the legacy approved bank
//                      nor the current phrase_texts.json bank (i.e. the
//                      sentence is hardcoded in the engine, not bank-driven).
//   ENGINE_ERROR     - engine threw for a permutation.
//
// Outputs:
//   tool/phrase_audit/output/inspection_audit.json
//   tool/phrase_audit/output/valuation_audit.json
//   tool/phrase_audit/output/audit_summary.md
//
// Run with:  flutter test test/phrase_audit/phrase_permutation_audit_test.dart
//
// The suite writes a detailed edit report and enforces non-regression quality
// gates. Reviewed modernisation/verified-variant exceptions may remain, but
// their baseline cannot increase.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_catalog.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_answer_validator.dart';

// ---------------------------------------------------------------------------
// Normalisation + approved-bank matching
// ---------------------------------------------------------------------------

/// Normalises bank templates and engine output onto one comparable form.
String normalizeForMatch(String text) {
  var t = text;
  t = t.replaceAll(r'\r\n', ' ');
  t = t.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ');
  t = t.replaceAll(RegExp(r'<[^>]+>'), '');
  t = t.replaceAll(' ', ' ');
  t = t.replaceAll('\r', ' ').replaceAll('\n', ' ');
  // Engine rewrites PVC -> uPVC; fold both spellings together.
  t = t.replaceAll(RegExp(r'\buPVC\b'), 'PVC');
  // Bank templates write optional plurals as "door(s)"/"window(s)"; engine
  // output collapses these to plain plurals ("doors"/"windows"). Fold both
  // forms so the two aren't judged as different sentences.
  t = t.replaceAllMapped(
    RegExp(r'(\w+)\(s\)'),
    (m) => '${m.group(1)}s',
  );
  t = t.replaceAllMapped(
    RegExp(r'(\w+)\(es\)'),
    (m) => '${m.group(1)}es',
  );
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.toLowerCase();
}

final RegExp _placeholderPattern = RegExp(r'\{[A-Z0-9_]+\}');

/// Converts an approved template into a regex where each {TOKEN} matches any
/// non-empty run of text.
///
/// Returns null for templates that carry too little literal text to act as a
/// discriminating matcher (e.g. `{CP_NOTES}` or master templates that are
/// pure placeholder sequences would otherwise match ANY sentence).
RegExp? templateToRegex(String template, {int minLiteralWords = 3}) {
  final normalized = normalizeForMatch(template);
  final literal = normalized.replaceAll(RegExp(r'\{[a-z0-9_]+\}'), ' ').trim();
  final literalWords =
      literal.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  if (literal.length < 12 || literalWords < minLiteralWords) return null;

  // Placeholders may resolve to empty (optional slots, e.g. the fence
  // sentence in the garden templates), so each placeholder becomes (.*?) and
  // the whitespace around it becomes elastic.
  final parts = normalized.split(RegExp(r'\{[a-z0-9_]+\}'));
  final buffer = StringBuffer(r'^\s*');
  for (var i = 0; i < parts.length; i++) {
    buffer.write(RegExp.escape(parts[i].trim()));
    if (i < parts.length - 1) buffer.write(r'\s*(.*?)\s*');
  }
  buffer.write(r'\s*$');
  return RegExp(buffer.toString());
}

class ApprovedBank {
  ApprovedBank({
    required this.legacyTemplates,
    required this.currentTemplates,
  });

  /// Legacy 2018 bank (masters + sub-phrases + issue/risk phrases).
  final List<RegExp> legacyTemplates;

  /// Current phrase_texts.json entries (includes deliberate edits).
  final List<RegExp> currentTemplates;

  final Map<String, bool> _legacyMatchCache = <String, bool>{};
  final Map<String, bool> _currentMatchCache = <String, bool>{};
  late final Map<String, List<RegExp>> _legacyIndex =
      _buildTemplateIndex(legacyTemplates);
  late final Map<String, List<RegExp>> _currentIndex =
      _buildTemplateIndex(currentTemplates);

  /// Raw echoes of user-typed input and standard fallbacks are not phrases
  /// and must not be judged against the bank.
  static const List<String> _skipExact = <String>[
    '',
    'not inspected',
    'sample detail', // harness text-field input echoed back verbatim
    '5', // harness number-field input echoed back verbatim
  ];

  /// "Notes:"/"Note:" lines are structural labels carrying free-text user
  /// input, not narrative phrases - mirrors ParagraphComposer's
  /// `_standalonePattern`, which already treats these as protected/
  /// never-merged. Not judged against the bank.
  static final RegExp _bareNotesHeading =
      RegExp(r'^notes?:', caseSensitive: false);

  bool matchesLegacy(String phrase) =>
      _matchesCached(legacyTemplates, phrase, _legacyMatchCache, _legacyIndex);
  bool matchesCurrent(String phrase) => _matchesCached(
      currentTemplates, phrase, _currentMatchCache, _currentIndex);

  bool _matchesCached(
    List<RegExp> templates,
    String phrase,
    Map<String, bool> cache,
    Map<String, List<RegExp>> index,
  ) {
    final normalized = normalizeForMatch(phrase);
    final cached = cache[normalized];
    if (cached != null) return cached;

    final result = _matchesNormalized(templates, normalized, index);
    cache[normalized] = result;
    return result;
  }

  bool _matchesNormalized(
    List<RegExp> templates,
    String normalized,
    Map<String, List<RegExp>> index,
  ) {
    if (_skipExact.contains(normalized)) return true;
    if (_bareNotesHeading.hasMatch(normalized)) return true;
    final candidates = <RegExp>{...index['*'] ?? const <RegExp>[]};
    for (final word in RegExp(r'[a-z0-9]+')
        .allMatches(normalized)
        .map((match) => match.group(0)!)) {
      candidates.addAll(index[word] ?? const <RegExp>[]);
    }
    for (final regex in candidates) {
      if (regex.hasMatch(normalized)) return true;
    }
    return false;
  }

  Map<String, List<RegExp>> _buildTemplateIndex(List<RegExp> templates) {
    const common = <String>{
      'this',
      'that',
      'with',
      'from',
      'have',
      'been',
      'were',
      'which',
      'should',
      'property',
    };
    final index = <String, List<RegExp>>{};
    for (final regex in templates) {
      final literalPattern =
          regex.pattern.replaceAll(RegExp(r'\\[a-zA-Z]'), ' ');
      final words = RegExp(r'[a-z0-9]+')
          .allMatches(literalPattern.toLowerCase())
          .map((match) => match.group(0)!)
          .where((word) => word.length >= 4 && !common.contains(word));
      final key = words.isEmpty ? '*' : words.first;
      index.putIfAbsent(key, () => <RegExp>[]).add(regex);
    }
    return index;
  }
}

/// Manually-reviewed template variants that are legitimate reduced forms of
/// an approved template (see tool/phrase_audit/reference/verified_variants.json
/// for the audit trail behind each entry).
List<String> loadVerifiedVariantTemplates() {
  final path = 'tool/phrase_audit/reference/verified_variants.json';
  final file = File(path);
  if (!file.existsSync()) return const [];
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (json['variants'] as List<dynamic>)
      .map((v) => (v as Map<String, dynamic>)['template'] as String)
      .toList();
}

ApprovedBank loadApprovedBank() {
  final legacyJson = jsonDecode(
    File('tool/phrase_audit/reference/old_phrase_bank.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  // Templates are split on <br/> boundaries so that each sentence-group in a
  // master/multi-line template becomes its own matcher.
  final splitter = RegExp(r'(?:\\r\\n|<br\s*/?>|\r|\n)+');

  List<RegExp> compile(Iterable<String> texts, {int minLiteralWords = 3}) {
    final regexes = <RegExp>[];
    for (final text in texts) {
      for (final segment in text.split(splitter)) {
        final regex =
            templateToRegex(segment, minLiteralWords: minLiteralWords);
        if (regex != null) regexes.add(regex);
      }
    }
    return regexes;
  }

  final legacyTexts = <String>[];
  for (final group in <String>[
    'phrases',
    'sub_phrases',
    'issue_phrases',
    'sub_issue_phrases',
    'risk_phrases',
    'sub_risk_phrases',
  ]) {
    for (final entry in (legacyJson[group] as List<dynamic>? ?? const [])) {
      final text = (entry as Map<String, dynamic>)['text'] as String? ?? '';
      if (text.trim().isNotEmpty) legacyTexts.add(text);
    }
  }

  final currentJson = jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final currentPhraseTexts =
      currentJson.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  final currentTexts =
      currentPhraseTexts.values.where((t) => t.trim().isNotEmpty).toList();

  return ApprovedBank(
    legacyTemplates: compile(legacyTexts),
    currentTemplates: [
      ...compile(currentTexts),
      // Manually reviewed entries are pre-vetted against the source bank, so
      // the discriminating-length heuristic (which exists to stop *inferred*
      // templates from over-matching) doesn't need to gate them as strictly.
      ...compile(loadVerifiedVariantTemplates(), minLiteralWords: 2),
    ],
  );
}

// ---------------------------------------------------------------------------
// Grammar smells
// ---------------------------------------------------------------------------

class GrammarSmell {
  const GrammarSmell(this.name, this.pattern);
  final String name;
  final RegExp pattern;
}

final List<GrammarSmell> grammarSmells = <GrammarSmell>[
  GrammarSmell('double_space', RegExp(r'  ')),
  GrammarSmell('doubled_word',
      RegExp(r'\b(of|the|a|an|and|in|is|are|to) \1\b', caseSensitive: false)),
  GrammarSmell(
      'of_mainly_of', RegExp(r'\bof mainly of\b', caseSensitive: false)),
  GrammarSmell('space_before_punct', RegExp(r'\s[.,;:](\s|$)')),
  GrammarSmell('double_period', RegExp(r'(?<!\.)\.\.(?!\.)')),
  GrammarSmell('empty_parentheses', RegExp(r'\(\s*\)')),
  GrammarSmell('lowercase_sentence_start', RegExp(r'(?:^|[.!?]\s+)[a-z]')),
  // Case-sensitive: engine-generated prose writes dangling conjunctions in
  // lowercase ("...confirmed and."). Case-insensitive matching here catches
  // single-uppercase-letter grade designators instead (e.g. EPC "Band A.",
  // where trailing "A" incidentally matches the article "a") - a false
  // positive, not a real dangling-conjunction defect.
  GrammarSmell(
      'orphan_conjunction_end', RegExp(r'\b(?:and|of|in|the|a|with|to)[.]?$')),
  GrammarSmell('covered_in_floor_above',
      RegExp(r'covered in [^.]*floor above', caseSensitive: false)),
  // A raw field id (e.g. "cb_others_373") leaking into report text means a
  // _labelsFor() call is missing a label entry for that checkbox/dropdown
  // id and fell back to the id itself.
  GrammarSmell('raw_field_id_leak', RegExp(r'\b(?:cb|et|actv)_[a-z0-9_]*\d')),
  // Engine substitutes '...' when a dependent answer is missing; these leak
  // into the report as literal ellipses.
  GrammarSmell('ellipsis_filler', RegExp(r'\.\.\.')),
  // Broken sentence from an empty slot, e.g. "to the of the property".
  GrammarSmell(
      'empty_slot_fragment',
      RegExp(r'\b(?:to|of|in|at|on|with) the (?:of|to|in|at|on|with)\b',
          caseSensitive: false)),
  // Sentence ends with a dangling "covered in ." style empty slot.
  GrammarSmell('dangling_slot_before_period',
      RegExp(r'\b(?:in|of|with|by|to)\s+[.](?:\s|$)', caseSensitive: false)),
];

/// Abbreviations whose internal periods are not sentence boundaries. Applied
/// only for smell DETECTION (temporarily masking the periods so
/// `lowercase_sentence_start` doesn't mistake "e.g. settlement" for a new
/// sentence starting lowercase) - never changes the stored/reported sample
/// text itself.
String _maskAbbreviations(String text) {
  return text
      .replaceAll(RegExp(r'\be\.g\.', caseSensitive: false), 'eg')
      .replaceAll(RegExp(r'\bi\.e\.', caseSensitive: false), 'ie')
      .replaceAll(RegExp(r'\betc\.', caseSensitive: false), 'etc');
}

List<String> grammarIssues(String phrase) {
  final issues = <String>[];
  final masked = _maskAbbreviations(phrase);
  for (final smell in grammarSmells) {
    if (smell.pattern.hasMatch(masked)) issues.add(smell.name);
  }
  return issues;
}

// ---------------------------------------------------------------------------
// Permutation generation
// ---------------------------------------------------------------------------

const int maxPermutationsPerScreen = 400;
const String sampleText = 'sample detail';
const String sampleNumber = '5';

List<Map<String, String>> buildPermutations(
    List<InspectionFieldDefinition> fields) {
  final permutations = <Map<String, String>>[<String, String>{}];

  final dataFields = fields
      .where((f) => f.type != InspectionFieldType.label)
      .toList(growable: false);

  // Solo permutations: each field exercised alone.
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

  // Maximal permutation: everything answered at once.
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

  // Option sweeps: every dropdown option with maximal context.
  for (final field in dataFields) {
    if (field.type != InspectionFieldType.dropdown) continue;
    for (final option in field.options ?? const <String>[]) {
      if (maximal[field.id] == option) continue;
      permutations.add({...maximal, field.id: option});
      if (permutations.length >= maxPermutationsPerScreen) break;
    }
    if (permutations.length >= maxPermutationsPerScreen) break;
  }

  return permutations.length > maxPermutationsPerScreen
      ? permutations.sublist(0, maxPermutationsPerScreen)
      : permutations;
}

// ---------------------------------------------------------------------------
// Audit runner
// ---------------------------------------------------------------------------

class ScreenFinding {
  ScreenFinding({
    required this.sectionKey,
    required this.screenId,
    required this.title,
    required this.dataFieldCount,
    required this.permutationCount,
  });

  final String sectionKey;
  final String screenId;
  final String title;
  final int dataFieldCount;
  final int permutationCount;

  bool producedOutput = false;
  bool placeholderLeak = false;
  final Set<String> grammar = <String>{};
  final Set<String> unapprovedSamples = <String>{};
  final Set<String> editedOnlySamples = <String>{};
  final Set<String> placeholderSamples = <String>{};
  final Set<String> grammarSamples = <String>{};
  String? engineError;
  int totalPhrases = 0;
  int approvedLegacy = 0;
  int approvedCurrentOnly = 0;
  int unapproved = 0;

  /// Screens deliberately silent because a sibling screen shares the same
  /// underlying checkbox/dropdown fields and already narrates them; wiring
  /// a handler here would duplicate that sentence in the assembled report.
  /// Verified by reading inspection_phrase_engine.dart and confirmed by the
  /// pre-existing "legacy no-op" test cases in
  /// inspection_phrase_engine_outside_doors_parity_test.dart and
  /// inspection_phrase_engine_windows_parity_test.dart. Not a gap.
  static const Set<String> _intentionalNoOpScreens = <String>{
    'activity_outside_property_windows_safety_glass_rating',
    'activity_outside_property_out_side_doors_repairs_failed_glazing_location',
    'activity_outside_property_out_side_doors_repairs_inadequate_lock_location',
    // Room counts are first-class structured data rendered in the
    // accommodation table; emitting prose here would duplicate that table.
    'activity_no_of_rooms',
    'activity_no_of_rooms__ground',
    'activity_no_of_rooms__first',
    'activity_no_of_rooms__second',
    'activity_no_of_rooms__third',
    'activity_no_of_rooms__other',
    'activity_no_of_rooms__roof_space',
  };

  bool get isGap =>
      dataFieldCount > 0 &&
      !producedOutput &&
      !_intentionalNoOpScreens.contains(screenId);

  List<String> get severities {
    final list = <String>[];
    if (engineError != null) list.add('ENGINE_ERROR');
    if (isGap) list.add('GAP');
    if (placeholderLeak) list.add('PLACEHOLDER_LEAK');
    if (unapproved > 0) list.add('UNAPPROVED');
    if (grammar.isNotEmpty) list.add('GRAMMAR');
    return list;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sectionKey': sectionKey,
        'screenId': screenId,
        'title': title,
        'dataFieldCount': dataFieldCount,
        'permutationCount': permutationCount,
        'severities': severities,
        'phraseStats': <String, int>{
          'total': totalPhrases,
          'approvedLegacy': approvedLegacy,
          'approvedCurrentBankOnly': approvedCurrentOnly,
          'unapproved': unapproved,
        },
        if (engineError != null) 'engineError': engineError,
        if (grammar.isNotEmpty) 'grammarIssues': grammar.toList()..sort(),
        if (unapprovedSamples.isNotEmpty)
          'unapprovedSamples': unapprovedSamples.take(5).toList(),
        if (editedOnlySamples.isNotEmpty)
          'editedBankSamples': editedOnlySamples.take(3).toList(),
        if (placeholderSamples.isNotEmpty)
          'placeholderSamples': placeholderSamples.take(3).toList(),
        if (grammarSamples.isNotEmpty)
          'grammarSamples': grammarSamples.take(5).toList(),
      };
}

List<ScreenFinding> auditTree({
  required InspectionTreePayload tree,
  required List<String> Function(String screenId, Map<String, String> answers)
      buildPhrases,
  required ApprovedBank bank,
  bool Function(String phrase)? matchesApproved,
  bool Function(String screenId, Map<String, String> answers)? isBlocked,
}) {
  final findings = <ScreenFinding>[];

  for (final section in tree.sections) {
    for (final node in section.nodes) {
      if (node.type != InspectionNodeType.screen) continue;

      final dataFields =
          node.fields.where((f) => f.type != InspectionFieldType.label).length;
      final permutations = buildPermutations(node.fields);
      final finding = ScreenFinding(
        sectionKey: section.key,
        screenId: node.id,
        title: node.title,
        dataFieldCount: dataFields,
        permutationCount: permutations.length,
      );

      final seenPhrases = <String>{};
      for (final answers in permutations) {
        if (isBlocked?.call(node.id, answers) ?? false) continue;
        List<String> phrases;
        try {
          phrases = buildPhrases(node.id, answers);
        } catch (e) {
          finding.engineError ??= e.toString();
          continue;
        }
        for (final phrase in phrases) {
          final trimmed = phrase.trim();
          if (trimmed.isEmpty) continue;
          finding.producedOutput = true;
          if (!seenPhrases.add(normalizeForMatch(trimmed))) continue;

          finding.totalPhrases++;
          if (_placeholderPattern.hasMatch(trimmed)) {
            finding.placeholderLeak = true;
            finding.placeholderSamples.add(trimmed);
          }
          // Raw echoes of the harness's own dummy free-text/number input
          // (sampleText/sampleNumber) are not narrative sentences - skip
          // grammar checking so the harness doesn't flag its own test
          // fixture as an app defect (matches the bank-matcher's
          // ApprovedBank._skipExact treatment of the same values).
          final isHarnessEcho = normalizeForMatch(trimmed) == sampleText ||
              normalizeForMatch(trimmed) == sampleNumber;
          if (!isHarnessEcho) {
            final issues = grammarIssues(trimmed);
            if (issues.isNotEmpty) {
              finding.grammar.addAll(issues);
              finding.grammarSamples.add(trimmed);
            }
          }
          if (isHarnessEcho) continue;
          if (matchesApproved != null && matchesApproved(trimmed)) {
            finding.approvedCurrentOnly++;
            finding.editedOnlySamples.add(trimmed);
          } else if (matchesApproved != null) {
            finding.unapproved++;
            finding.unapprovedSamples.add(trimmed);
          } else if (bank.matchesLegacy(trimmed)) {
            finding.approvedLegacy++;
          } else if (bank.matchesCurrent(trimmed)) {
            finding.approvedCurrentOnly++;
            finding.editedOnlySamples.add(trimmed);
          } else {
            finding.unapproved++;
            finding.unapprovedSamples.add(trimmed);
          }
        }
      }
      findings.add(finding);
    }
  }
  return findings;
}

Map<String, dynamic> summarize(String label, List<ScreenFinding> findings) {
  int count(String severity) =>
      findings.where((f) => f.severities.contains(severity)).length;
  final totalPhrases = findings.fold<int>(0, (sum, f) => sum + f.totalPhrases);
  final unapprovedPhrases =
      findings.fold<int>(0, (sum, f) => sum + f.unapproved);
  final legacyApproved =
      findings.fold<int>(0, (sum, f) => sum + f.approvedLegacy);
  return <String, dynamic>{
    'tree': label,
    'screensAudited': findings.length,
    'screensWithFindings':
        findings.where((f) => f.severities.isNotEmpty).length,
    'bySeverity': <String, int>{
      'GAP': count('GAP'),
      'UNAPPROVED': count('UNAPPROVED'),
      'GRAMMAR': count('GRAMMAR'),
      'PLACEHOLDER_LEAK': count('PLACEHOLDER_LEAK'),
      'ENGINE_ERROR': count('ENGINE_ERROR'),
    },
    'phrases': <String, int>{
      'distinctEmitted': totalPhrases,
      'approvedLegacyBank': legacyApproved,
      'approvedCurrentBankOnly':
          findings.fold<int>(0, (sum, f) => sum + f.approvedCurrentOnly),
      'unapproved': unapprovedPhrases,
    },
  };
}

void writeReports({
  required List<ScreenFinding> inspection,
  required List<ScreenFinding> valuation,
}) {
  final outDir = Directory('tool/phrase_audit/output');
  outDir.createSync(recursive: true);

  const encoder = JsonEncoder.withIndent(' ');

  File('${outDir.path}/inspection_audit.json')
      .writeAsStringSync(encoder.convert(<String, dynamic>{
    'summary': summarize('inspection_v2', inspection),
    'screens': inspection.map((f) => f.toJson()).toList(),
  }));
  File('${outDir.path}/valuation_audit.json')
      .writeAsStringSync(encoder.convert(<String, dynamic>{
    'summary': summarize('valuation_v2', valuation),
    'screens': valuation.map((f) => f.toJson()).toList(),
  }));

  final md = StringBuffer()
    ..writeln('# Phrase Permutation Audit Summary')
    ..writeln()
    ..writeln('Generated: ${DateTime.now().toIso8601String()}')
    ..writeln();
  for (final entry in <(String, List<ScreenFinding>)>[
    ('Inspection', inspection),
    ('Valuation', valuation),
  ]) {
    final summary = summarize(entry.$1, entry.$2);
    final by = summary['bySeverity'] as Map<String, int>;
    final ph = summary['phrases'] as Map<String, int>;
    md
      ..writeln('## ${entry.$1} tree')
      ..writeln()
      ..writeln('| Metric | Value |')
      ..writeln('|---|---|')
      ..writeln('| Screens audited | ${summary['screensAudited']} |')
      ..writeln('| Screens with findings | ${summary['screensWithFindings']} |')
      ..writeln('| GAP (no phrase generated) | ${by['GAP']} |')
      ..writeln('| UNAPPROVED phrases present | ${by['UNAPPROVED']} |')
      ..writeln('| Grammar smells | ${by['GRAMMAR']} |')
      ..writeln('| Placeholder leaks | ${by['PLACEHOLDER_LEAK']} |')
      ..writeln('| Engine errors | ${by['ENGINE_ERROR']} |')
      ..writeln('| Distinct phrases emitted | ${ph['distinctEmitted']} |')
      ..writeln('| Matching legacy approved bank | '
          '${ph['approvedLegacyBank']} |')
      ..writeln('| Matching current bank only (edited) | '
          '${ph['approvedCurrentBankOnly']} |')
      ..writeln('| Unapproved (engine-invented) | ${ph['unapproved']} |')
      ..writeln();

    final worst = entry.$2.where((f) => f.severities.isNotEmpty).toList()
      ..sort((a, b) => b.severities.length.compareTo(a.severities.length));
    md
      ..writeln('### Top findings')
      ..writeln()
      ..writeln('| Screen | Section | Findings | Sample |')
      ..writeln('|---|---|---|---|');
    for (final f in worst.take(25)) {
      final sample = (f.unapprovedSamples.isNotEmpty
              ? f.unapprovedSamples.first
              : f.grammarSamples.isNotEmpty
                  ? f.grammarSamples.first
                  : f.placeholderSamples.isNotEmpty
                      ? f.placeholderSamples.first
                      : '')
          .replaceAll('|', r'\|');
      final clipped =
          sample.length > 90 ? '${sample.substring(0, 90)}…' : sample;
      md.writeln('| `${f.screenId}` | ${f.sectionKey} | '
          '${f.severities.join(', ')} | $clipped |');
    }
    md.writeln();
  }
  File('${outDir.path}/audit_summary.md').writeAsStringSync(md.toString());
}

// ---------------------------------------------------------------------------
// Test entry point
// ---------------------------------------------------------------------------

void main() {
  test('ApprovedBank rejects fabricated sentences (matcher sanity guard)', () {
    // Phase 4b added a composite-segment matcher for multi-placeholder
    // paragraph groups (e.g. {CONSTRUCTION} {UNDERLINING_STATUS}). This
    // guards against that matcher becoming pathologically permissive -
    // if it ever starts approving arbitrary text, every other assertion in
    // this file becomes meaningless.
    final bank = loadApprovedBank();
    const fabricated = <String>[
      'The spaceship engine requires immediate dilithium crystal replacement.',
      'This property was inspected by a certified unicorn on Tuesday.',
      'Random unrelated sentence that no template could ever produce here.',
      'The kitchen appliances were purchased from a discount warehouse in 1997.',
    ];
    for (final phrase in fabricated) {
      expect(
        bank.matchesLegacy(phrase) || bank.matchesCurrent(phrase),
        isFalse,
        reason: 'matcher must not approve fabricated text: "$phrase"',
      );
    }
  });

  test('phrase permutation audit', () {
    final bank = loadApprovedBank();
    expect(bank.legacyTemplates.length, greaterThan(900),
        reason: 'legacy bank must load (79 masters + 710 subs + issue/risk)');

    final phraseTexts = (jsonDecode(
      File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
    ) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
    final inspectionEngine = InspectionPhraseEngine(phraseTexts);

    final inspectionTree = InspectionTreePayload.fromJson(
      File('assets/property_inspection/inspection_tree.json')
          .readAsStringSync(),
    );
    expect(inspectionTree.sections, isNotEmpty);

    final valuationTree = InspectionTreePayload.fromJson(
      File('assets/property_valuation/valuation_tree.json').readAsStringSync(),
    );
    expect(valuationTree.sections, isNotEmpty);

    final valuationCatalog = ValuationPhraseCatalog.fromRawJson(
      File('assets/property_valuation/phrase_texts.json').readAsStringSync(),
    );
    final valuationEngine = ValuationPhraseEngine.catalog(valuationCatalog);

    final inspectionFindings = auditTree(
      tree: inspectionTree,
      buildPhrases: inspectionEngine.buildPhrases,
      bank: bank,
    );
    final valuationFindings = auditTree(
      tree: valuationTree,
      buildPhrases: valuationEngine.buildPhrases,
      bank: bank,
      matchesApproved: (phrase) =>
          valuationCatalog.matchTemplateId(phrase) != null,
      isBlocked: (screenId, answers) =>
          ValuationAnswerValidator.validateScreen(screenId, answers).isNotEmpty,
    );

    writeReports(
      inspection: inspectionFindings,
      valuation: valuationFindings,
    );

    final inspectionSummary = summarize('inspection_v2', inspectionFindings);
    final inspectionSeverity =
        inspectionSummary['bySeverity'] as Map<String, int>;
    final inspectionPhrases = inspectionSummary['phrases'] as Map<String, int>;
    expect(inspectionSeverity['GAP'], 0);
    expect(inspectionSeverity['PLACEHOLDER_LEAK'], 0);
    expect(inspectionSeverity['ENGINE_ERROR'], 0);
    expect(inspectionSeverity['GRAMMAR'], 0);
    expect(inspectionSeverity['UNAPPROVED'], 0);
    expect(inspectionPhrases['unapproved'], 0);

    final valuationSummary = summarize('valuation_v2', valuationFindings);
    final valuationSeverity =
        valuationSummary['bySeverity'] as Map<String, int>;
    expect(valuationSeverity['GAP'], 0);
    expect(valuationSeverity['PLACEHOLDER_LEAK'], 0);
    expect(valuationSeverity['ENGINE_ERROR'], 0);
    expect(valuationSeverity['GRAMMAR'], 0);
    expect(valuationSeverity['UNAPPROVED'], 0);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
