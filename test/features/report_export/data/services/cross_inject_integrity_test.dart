import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Phase 3 — cross-injection integrity.
///
/// The RICS L2 Master Phrase Library marks 35 "Add text to: Section X"
/// directives: when a defect is recorded on a source (E-section) screen, the
/// same sentence must also surface in a target section (J1 Risks to the
/// Building, J3 Risks to People, I1 Regulations, I2 Guarantees).
///
/// This is the durable guarantee that every one of those 35 directives is
/// accounted for — sourced verbatim from the digitised spec
/// (`rics_l2_library.json`, the wording source of truth) and checked against
/// the `report_builder.dart` derivation functions that emit the injected
/// sentences. Static conformance test (no rendering) → fast, and it cannot
/// silently rot if a future edit drops an injection.
///
/// Target → emitting derivation function:
///   J1        → _legacyDerivedSectionFRiskToBuilding
///   J3        → _legacyDerivedSectionFRiskToPeople
///   I2, J2*   → _legacyDerivedSectionFIssueGuarantees   (*spec's "J2
///               Guarantees" is the known typo for I2; the app has no J2)
///
/// Three of the 35 are PARKED content-gaps (no source input field exists, so
/// nothing can be wired without new UI — an Open Decisions Register item, not a
/// bug). They are asserted ABSENT so the exception stays explicit and audited:
///   • E4 → I1  "external alterations" (I1 comes from its own screen)
///   • E2 → J1  roof-to-wall flashing junction (no dedicated roof-flashing screen)
///   • E4 → J1  tree DEFECTS noted (screen captures tree size only, always the
///              "no obvious signs of damage" variant)
void main() {
  final repoRoot = _repoRoot();
  final spec = jsonDecode(
    File('${repoRoot.path}/tool/phrase_audit/reference/rics_l2_library.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  final builderSrc = File(
    '${repoRoot.path}/lib/features/report_export/data/services/report_builder.dart',
  ).readAsStringSync();

  final fnBodies = _derivationFunctionBodies(builderSrc);
  final normBodies = <String, String>{
    for (final e in fnBodies.entries) e.key: _norm(e.value),
  };
  final normAll = _norm(builderSrc);

  final injects = _specCrossInjects(spec);

  // Injections whose code wording legitimately diverges from the spec's
  // truncated textStart (same sentence, reworded / conditional article). The
  // value is a distinctive fragment that MUST be present in the target fn.
  const wordingOverrides = <String, String>{
    // E1 → J3: code emits "An aerial attached to the property is loose…"
    'an aerial or satellite dish attached': 'attached to the property is loose',
    // E2 → J1: code emits "The roof slopes appear uneven or undulating…"
    'the roof slopes to the front': 'roof slopes appear uneven or undulating',
  };

  // The 3 parked content-gaps: distinctive text that must be ABSENT from the
  // derivation functions (nothing can be wired without a new input field).
  const parkedSignatures = <String>[
    'external alterations', // E4 → I1
    'waterproofing at the junction of the roof covering and wall', // E2 → J1
    'trees located close to the property, and i noted defects', // E4 → J1
  ];

  test('spec declares exactly 35 cross-injections', () {
    expect(spec['crossInjectCount'], 35);
    expect(injects.length, 35);
  });

  test('every wired cross-inject is present in its target derivation function',
      () {
    const targetToFn = <String, String>{
      'J1': '_legacyDerivedSectionFRiskToBuilding',
      'J3': '_legacyDerivedSectionFRiskToPeople',
      'I2': '_legacyDerivedSectionFIssueGuarantees',
      'J2': '_legacyDerivedSectionFIssueGuarantees', // spec typo → I2
    };

    final missing = <String>[];
    var wired = 0;
    var parked = 0;

    for (final inject in injects) {
      final stem = _searchStem(inject.textStart);
      if (_isParked(stem, inject, parkedSignatures)) {
        parked++;
        continue;
      }
      if (inject.target == 'I1') {
        // The only I1 inject is parked (handled above); guard against a new one.
        missing.add('[unexpected I1 inject] "$stem"');
        continue;
      }
      final fnName = targetToFn[inject.target];
      expect(fnName, isNotNull,
          reason: 'Unmapped cross-inject target "${inject.target}"');
      final haystack = normBodies[fnName]!;
      final needle = wordingOverrides[stem] ?? stem;
      wired++;
      if (!haystack.contains(_norm(needle))) {
        missing.add('[${inject.target} ← ${inject.source}] "$needle"');
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'Spec cross-injections not wired into their target function:\n'
          '${missing.join('\n')}',
    );
    expect(parked, 3, reason: 'Expected exactly 3 parked content-gap injects');
    expect(wired, 32, reason: 'Expected 32 wired injects (35 − 3 parked)');
  });

  test('the 3 parked content-gap injects are absent from the derivation code',
      () {
    for (final sig in parkedSignatures) {
      expect(normAll, isNot(contains(_norm(sig))),
          reason: 'Parked content-gap "$sig" should not be wired');
    }
  });

  test('E4 structural-movement → I2 Guarantees is wired (Phase 3 fix)', () {
    final i2 = normBodies['_legacyDerivedSectionFIssueGuarantees']!;
    expect(i2, contains(_norm('damaged by movement cracks potentially arising')));
    expect(i2, contains(_norm('recent cracking suggests that movement may have recurred')));
    expect(i2, contains('see section e4 main walls'));
  });
}

// ─────────────────────────────────────────────────────────────────────────

class _Inject {
  const _Inject(this.source, this.target, this.textStart);
  final String source;
  final String target;
  final String textStart;
}

bool _isParked(String stem, _Inject inject, List<String> parked) {
  final n = _norm(stem);
  for (final p in parked) {
    final np = _norm(p);
    if (np.contains(n) || n.contains(np.split(' ').take(4).join(' '))) {
      return true;
    }
  }
  // Distinguish the two E4→J1 injects that share "trees": only the DEFECTS
  // variant is parked; the (unrelated) items are matched above by text.
  return false;
}

List<_Inject> _specCrossInjects(Map<String, dynamic> spec) {
  final out = <_Inject>[];
  for (final entry in (spec['entries'] as List).cast<Map<String, dynamic>>()) {
    final ci = entry['crossInjects'];
    if (ci is! List) continue;
    for (final c in ci.cast<Map<String, dynamic>>()) {
      out.add(_Inject(
        entry['key'] as String,
        c['target'] as String,
        c['textStart'] as String,
      ));
    }
  }
  return out;
}

/// Strips the section-label prefix the spec prepends ("Risk to Building - ",
/// "Guarantees - ", "Regulations -" …, case-insensitively) and returns a
/// normalised distinctive leading fragment robust to mid-sentence truncation.
String _searchStem(String textStart) {
  var s = textStart;
  final lower = s.toLowerCase();
  for (final prefix in const <String>[
    'risk to building -',
    'risk to people -',
    'guarantees -',
    'regulations -',
  ]) {
    if (lower.startsWith(prefix)) {
      s = s.substring(prefix.length);
      break;
    }
  }
  final words = _norm(s).split(' ').where((w) => w.isNotEmpty).toList();
  return words.take(6).join(' ');
}

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

Map<String, String> _derivationFunctionBodies(String src) {
  final decl = RegExp(r'List<String> (_legacyDerivedSectionF\w+)\(');
  final matches = decl.allMatches(src).toList();
  final bodies = <String, String>{};
  for (var i = 0; i < matches.length; i++) {
    final name = matches[i].group(1)!;
    final start = matches[i].start;
    final end = i + 1 < matches.length ? matches[i + 1].start : src.length;
    bodies.putIfAbsent(name, () => src.substring(start, end));
  }
  return bodies;
}

Directory _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  return Directory.current;
}
