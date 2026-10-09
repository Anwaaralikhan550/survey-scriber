import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

/// Generated checks for every rule in `kVerbatimRules`
/// (lib/.../inspection_verbatim_spec.dart):
///
///  * T3 - the form offers exactly the option list the PDF prints
///    (field type, label text, order for dropdowns).
///  * T5 - choosing each option emits the approved bank sentence with that
///    option's text in it; several choices are joined; "Other" prints the
///    typed text; no `{TOKEN}` ever leaks.
void main() {
  final bank = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v.toString()));
  final tree = jsonDecode(
    File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
  );
  final engine = InspectionPhraseEngine(bank);

  final fieldsByScreen = <String, Map<String, Map<String, dynamic>>>{};
  void walk(dynamic n) {
    if (n is Map<String, dynamic>) {
      final id = n['id'];
      final fields = n['fields'];
      if (id is String && fields is List) {
        fieldsByScreen[id] = {
          for (final f in fields)
            if (f is Map<String, dynamic>) f['id'] as String: f,
        };
      }
      n.values.forEach(walk);
    } else if (n is List) {
      n.forEach(walk);
    }
  }

  walk(tree);

  String collapse(String t) => t.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Mirrors what the engine does to bank text before it reaches the report.
  String plain(String t) {
    var c = t.replaceAll(r'\r\n', '\n');
    c = c.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    c = c.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll(' ', ' ');
    c = c.replaceAll(RegExp(r'\bPVC\b'), 'uPVC');
    return collapse(c);
  }

  /// The value as it is printed (lower-cased when the rule says so).
  String shown(VerbatimToken t, String v) => t.lower ? v.toLowerCase() : v;

  String masterFor(VerbatimRule r) =>
      r.master == '@chimney' ? '{E_CHIMNEY_SINGLE_STACK}' : r.master;

  for (final rule in kVerbatimRules) {
    group('verbatim rule ${rule.id}', () {
      final fields = fieldsByScreen[rule.screen];
      final template = bank['${masterFor(rule)}::${rule.sub}'];

      test('screen and bank sentence exist', () {
        expect(fields, isNotNull, reason: 'screen ${rule.screen}');
        expect(template, isNotNull,
            reason: 'bank key ${masterFor(rule)}::${rule.sub}');
        for (final t in rule.tokens) {
          expect(template, contains(t.token), reason: t.token);
        }
      });

      test('form options equal the PDF option lists (T3)', () {
        for (final t in rule.tokens) {
          if (t.dropdown != null) {
            final f = fields![t.dropdown]!;
            expect(f['type'], 'dropdown', reason: t.dropdown);
            expect(f['options'], t.dropdownOptions, reason: t.dropdown);
            expect(
              t.lower
                  ? t.dropdownOptions.map((o) => o.toLowerCase()).toList()
                  : t.dropdownOptions,
              t.pdfOptions,
              reason: t.dropdown,
            );
          } else if (t.text != null) {
            expect(fields![t.text]!['type'], 'text');
          } else {
            expect(t.options.values.toList(), t.pdfOptions, reason: t.token);
            t.options.forEach((id, label) {
              final f = fields![id];
              expect(f, isNotNull, reason: id);
              expect(f!['type'], 'checkbox', reason: id);
              expect(f['label'], label, reason: id);
            });
            if (t.otherCheckbox != null) {
              expect(fields![t.otherCheckbox]!['type'], 'checkbox');
              expect(fields[t.otherCheckbox]!['label'], 'Other');
              expect(fields[t.otherText]!['type'], 'text');
            }
          }
        }
      });

      // Answers that make every token non-empty (first option of each).
      Map<String, String> base() {
        final a = <String, String>{};
        if (rule.whenField != null) a[rule.whenField!] = rule.whenValue!;
        for (final t in rule.tokens) {
          if (t.constant != null) continue;
          if (t.dropdown != null) {
            a[t.dropdown!] = t.dropdownOptions.first;
          } else if (t.text != null) {
            a[t.text!] = 'sample';
          } else {
            a[t.options.keys.first] = 'true';
          }
        }
        return a;
      }

      String expected(Map<String, String> values, {int count = 1}) {
        var s = template!;
        values.forEach((token, v) {
          final tok = rule.tokens.firstWhere((x) => x.token == token);
          final shown = tok.cap && v.isNotEmpty
              ? v[0].toUpperCase() + v.substring(1)
              : v;
          s = s.replaceAll(token, shown);
        });
        if (rule.isAre) s = s.replaceAll('{IS_ARE}', count > 1 ? 'are' : 'is');
        return plain(s);
      }

      Map<String, String> firstValues() {
        final m = <String, String>{};
        for (final t in rule.tokens) {
          m[t.token] = t.constant != null
              ? t.constant!
              : t.dropdown != null
                  ? shown(t, t.dropdownOptions.first)
                  : t.text != null
                      ? 'sample'
                      : t.options.values.first;
        }
        return m;
      }

      String run(Map<String, String> answers) => collapse(engine
          .buildPhrases(
            rule.screen,
            {
              if (rule.whenField != null) rule.whenField!: rule.whenValue!,
              ...answers,
            },
          )
          .join(' '));

      test('every option emits the exact bank sentence (T5)', () {
        if (rule.tokens.every((t) => t.constant != null)) {
          expect(run({}), contains(expected(firstValues())));
        }
        for (final t in rule.tokens) {
          if (t.dropdown != null) {
            for (final v in t.dropdownOptions) {
              final a = base()..[t.dropdown!] = v;
              final out = run(a);
              expect(
                  out,
                  contains(
                      expected({...firstValues(), t.token: shown(t, v)})),
                  reason: '${t.dropdown}=$v');
              expect(out, isNot(contains('{')), reason: '${t.dropdown}=$v');
            }
          } else if (t.text == null) {
            for (final e in t.options.entries) {
              final a = base()..removeWhere((k, _) => t.options.containsKey(k));
              a[e.key] = 'true';
              final out = run(a);
              expect(out, contains(expected({...firstValues(), t.token: e.value})),
                  reason: e.key);
              expect(out, isNot(contains('{')), reason: e.key);
            }
          }
        }
      });

      test('several choices are joined and Other prints the typed text', () {
        for (final t in rule.tokens) {
          if (t.dropdown != null || t.text != null || t.options.length < 2) {
            continue;
          }
          final ids = t.options.keys.toList();
          final a = base()..removeWhere((k, _) => t.options.containsKey(k));
          a[ids[0]] = 'true';
          a[ids[1]] = 'true';
          final two = '${t.options[ids[0]]} and ${t.options[ids[1]]}';
          expect(run(a),
              contains(expected({...firstValues(), t.token: two}, count: 2)));
          if (t.otherCheckbox != null) {
            final b = base()..removeWhere((k, _) => t.options.containsKey(k));
            b[t.otherCheckbox!] = 'true';
            b[t.otherText!] = 'zzz typed';
            expect(run(b),
                contains(expected({...firstValues(), t.token: 'zzz typed'})));
          }
        }
      });

      test('nothing chosen emits nothing from this rule', () {
        final stem = plain(template!.split('{').first);
        final alwaysOn = rule.whenField == null &&
            rule.tokens.every((t) => t.constant != null || t.optional);
        if (stem.length > 12 && !alwaysOn) {
          final bare = collapse(engine.buildPhrases(rule.screen, {}).join(' '));
          expect(bare, isNot(contains(stem)));
        }
      });
    });
  }
}
